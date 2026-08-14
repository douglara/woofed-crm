# frozen_string_literal: true

require "rails_helper"

RSpec.describe Plugins::BuildManager do
  let(:tmpdir) { Rails.root.join("tmp", "plugin_test_#{SecureRandom.hex(4)}") }
  let(:manager) { described_class.new(root: tmpdir) }

  before do
    Plugins::FilePatch.clear_registry!
    FileUtils.mkdir_p(tmpdir)
  end

  after do
    Plugins::FilePatch.clear_registry!
    FileUtils.rm_rf(tmpdir)
  end

  # Registers a plugin in the DB (BuildManager discovers plugins DB-first) whose
  # directory lives under the manager root at storage/plugins/<id>.
  def register_plugin(id, priority: 0)
    create(:plugin, id: id, priority: priority, status: "active")
  end

  def create_file(relative_path, content)
    path = tmpdir.join(relative_path)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
    path
  end

  describe "#sync!" do
    context "with a new file (no original in app/)" do
      it "copies the file as-is to storage/build/" do
        register_plugin("example")
        create_file("storage/plugins/example/app/models/new_model.rb", "class NewModel\nend\n")

        manager.sync!

        built = tmpdir.join("storage/build/app/models/new_model.rb")
        expect(built).to exist
        expect(built.read).to eq("class NewModel\nend\n")
      end
    end

    context "with a patch file (original exists in app/)" do
      it "applies the patch DSL over the original" do
        register_plugin("example")
        create_file("app/models/contact.rb", <<~RUBY)
          class Contact < ApplicationRecord
            ROLES = %w[admin user]
          end
        RUBY

        create_file("storage/plugins/example/app/models/contact.rb", <<~RUBY)
          Plugins::FilePatch.define target: "app/models/contact.rb" do
            after_line containing: "class Contact < ApplicationRecord" do
              "  include MyExtension"
            end
          end
        RUBY

        manager.sync!

        built = tmpdir.join("storage/build/app/models/contact.rb")
        expect(built).to exist
        content = built.read
        expect(content).to include("include MyExtension")
        expect(content).to include("class Contact < ApplicationRecord")
      end

      it "does not modify the original file" do
        register_plugin("example")
        original_content = "class Contact\nend\n"
        create_file("app/models/contact.rb", original_content)
        create_file("storage/plugins/example/app/models/contact.rb", <<~RUBY)
          Plugins::FilePatch.define target: "app/models/contact.rb" do
            after_line containing: "class Contact" do
              "  include MyExtension"
            end
          end
        RUBY

        manager.sync!

        original = tmpdir.join("app/models/contact.rb")
        expect(original.read).to eq(original_content)
      end
    end

    context "with multiple plugins patching the same file" do
      it "applies patches in priority order" do
        register_plugin("alpha", priority: 10)
        register_plugin("beta", priority: 20)

        create_file("app/models/contact.rb", <<~RUBY)
          class Contact < ApplicationRecord
          end
        RUBY

        create_file("storage/plugins/alpha/app/models/contact.rb", <<~RUBY)
          Plugins::FilePatch.define target: "app/models/contact.rb", priority: 10 do
            after_line containing: "class Contact < ApplicationRecord" do
              "  include Alpha"
            end
          end
        RUBY

        create_file("storage/plugins/beta/app/models/contact.rb", <<~RUBY)
          Plugins::FilePatch.define target: "app/models/contact.rb", priority: 20 do
            after_line containing: "include Alpha" do
              "  include Beta"
            end
          end
        RUBY

        manager.sync!

        built = tmpdir.join("storage/build/app/models/contact.rb")
        content = built.read
        expect(content).to include("include Alpha")
        expect(content).to include("include Beta")

        lines = content.lines.map(&:strip)
        alpha_idx = lines.index("include Alpha")
        beta_idx = lines.index("include Beta")
        expect(alpha_idx).to be < beta_idx
      end
    end

    context "with no active plugin records" do
      it "composes nothing" do
        # Files on disk but no Plugin record → ignored entirely.
        create_file("storage/plugins/orphan/app/models/ghost.rb", "class Ghost\nend\n")

        manager.sync!

        expect(manager.status).to eq([])
      end
    end

    context "ordering driven by the database priority" do
      it "lets the higher-priority plugin win when both provide the same new file" do
        register_plugin("low", priority: 1)
        register_plugin("high", priority: 2)

        create_file("storage/plugins/low/app/models/shared.rb", "class Shared; VALUE = :low; end\n")
        create_file("storage/plugins/high/app/models/shared.rb", "class Shared; VALUE = :high; end\n")

        manager.sync!

        built = tmpdir.join("storage/build/app/models/shared.rb")
        expect(built.read).to include("VALUE = :high")
      end
    end
  end

  describe "#rebuild!" do
    it "wipes and recreates storage/build/" do
      register_plugin("example")
      create_file("storage/plugins/example/app/models/new_model.rb", "class NewModel\nend\n")

      manager.sync!
      expect(tmpdir.join("storage/build/app/models/new_model.rb")).to exist

      # Add a rogue file
      rogue = tmpdir.join("storage/build/app/models/rogue.rb")
      FileUtils.mkdir_p(rogue.dirname)
      File.write(rogue, "rogue")

      manager.rebuild!

      expect(tmpdir.join("storage/build/app/models/new_model.rb")).to exist
      expect(rogue).not_to exist
    end
  end

  describe "#remove_orphans!" do
    it "removes files from storage/build/ when plugin is gone" do
      plugin = register_plugin("example")
      create_file("storage/plugins/example/app/models/new_model.rb", "class NewModel\nend\n")

      manager.sync!
      expect(tmpdir.join("storage/build/app/models/new_model.rb")).to exist

      # Remove the plugin (record + files)
      plugin.destroy!
      FileUtils.rm_rf(tmpdir.join("storage/plugins/example"))

      manager.sync!
      expect(tmpdir.join("storage/build/app/models/new_model.rb")).not_to exist
    end
  end

  describe "#preview" do
    it "returns the composed output for a target" do
      register_plugin("example")
      create_file("app/models/contact.rb", <<~RUBY)
        class Contact < ApplicationRecord
        end
      RUBY

      create_file("storage/plugins/example/app/models/contact.rb", <<~RUBY)
        Plugins::FilePatch.define target: "app/models/contact.rb" do
          after_line containing: "class Contact" do
            "  include MyExtension"
          end
        end
      RUBY

      manager.sync!

      result = manager.preview("app/models/contact.rb")
      expect(result).to include("include MyExtension")
    end

    it "returns nil for nonexistent targets" do
      expect(manager.preview("app/models/nonexistent.rb")).to be_nil
    end
  end

  describe "#status" do
    it "lists all files in storage/build/" do
      register_plugin("example")
      create_file("storage/plugins/example/app/models/new_model.rb", "class NewModel\nend\n")
      create_file("storage/plugins/example/app/models/another.rb", "class Another\nend\n")

      manager.sync!

      files = manager.status
      expect(files).to include("app/models/new_model.rb")
      expect(files).to include("app/models/another.rb")
    end

    it "returns empty array when storage/build/ does not exist" do
      expect(manager.status).to eq([])
    end
  end

  describe "incremental build" do
    it "does not rewrite unchanged files" do
      register_plugin("example")
      create_file("storage/plugins/example/app/models/new_model.rb", "class NewModel\nend\n")

      manager.sync!

      built = tmpdir.join("storage/build/app/models/new_model.rb")
      first_mtime = built.mtime

      sleep 0.1
      manager.sync!

      expect(built.mtime).to eq(first_mtime)
    end

    it "recreates a copied file deleted from storage/build/ while its fingerprint remains" do
      register_plugin("example")
      create_file("storage/plugins/example/app/models/new_model.rb", "class NewModel\nend\n")

      manager.sync!

      built = tmpdir.join("storage/build/app/models/new_model.rb")
      FileUtils.rm(built)
      expect(tmpdir.join("tmp/plugin_fingerprints")).to exist

      manager.sync!

      expect(built).to exist
      expect(built.read).to eq("class NewModel\nend\n")
    end

    it "recreates a composed file deleted from storage/build/ while its fingerprint remains" do
      register_plugin("example")
      create_file("app/models/contact.rb", "class Contact < ApplicationRecord\nend\n")
      create_file("storage/plugins/example/app/models/contact.rb", <<~RUBY)
        Plugins::FilePatch.define target: "app/models/contact.rb" do
          after_line containing: "class Contact < ApplicationRecord" do
            "  include MyExtension"
          end
        end
      RUBY

      manager.sync!

      built = tmpdir.join("storage/build/app/models/contact.rb")
      FileUtils.rm(built)

      manager.sync!

      expect(built).to exist
      expect(built.read).to include("include MyExtension")
    end
  end

  describe "ERB patching" do
    it "patches ERB view files" do
      register_plugin("example")
      create_file("app/views/users/show.html.erb", <<~ERB)
        <div class="user-card">
          <h1><%= @user.name %></h1>
          <%# plugin:example:start %>
          <%# plugin:example:end %>
        </div>
      ERB

      create_file("storage/plugins/example/app/views/users/show.html.erb", <<~RUBY)
        Plugins::FilePatch.define target: "app/views/users/show.html.erb" do
          replace_block from: "<%# plugin:example:start %>",
                        to: "<%# plugin:example:end %>" do
            "  <section>plugin content</section>"
          end
        end
      RUBY

      manager.sync!

      built = tmpdir.join("storage/build/app/views/users/show.html.erb")
      content = built.read
      expect(content).to include("<section>plugin content</section>")
      expect(content).not_to include("plugin:example:start")
    end
  end

  describe "config/ files" do
    it "copies config files but skips routes.rb" do
      register_plugin("example")
      create_file("storage/plugins/example/config/locales/example.en.yml", "en:\n  hello: Hi\n")
      create_file("storage/plugins/example/config/routes.rb", "# drawn separately by the loader")

      manager.sync!

      expect(tmpdir.join("storage/build/config/locales/example.en.yml")).to exist
      expect(tmpdir.join("storage/build/config/routes.rb")).not_to exist
    end
  end

  describe "Vite patch manifest" do
    it "writes a JSON manifest for JS patches" do
      register_plugin("example")
      create_file("app/javascript/pages/UserProfile.jsx", <<~JSX)
        import React from "react"
        export default function UserProfile() { return <div /> }
      JSX

      create_file("storage/plugins/example/app/javascript/pages/UserProfile.jsx", <<~RUBY)
        Plugins::FilePatch.define target: "app/javascript/pages/UserProfile.jsx" do
          after_line containing: 'import React from "react"' do
            'import Badge from "@/components/Badge"'
          end
        end
      RUBY

      manager.sync!

      manifest_path = tmpdir.join("tmp", "plugin_patches_test.json")
      expect(manifest_path).to exist

      manifest = JSON.parse(manifest_path.read)
      expect(manifest).to have_key("app/javascript/pages/UserProfile.jsx")

      patches = manifest["app/javascript/pages/UserProfile.jsx"]
      expect(patches.first["type"]).to eq("after_line")
      expect(patches.first["match"]).to include("import React")
    end

    it "serializes every operation type for JS targets" do
      register_plugin("example")
      create_file("app/javascript/app.js", <<~JS)
        import React from "react"
        const start = 1
        const stop = 2
        const old = 0
      JS

      create_file("storage/plugins/example/app/javascript/app.js", <<~RUBY)
        Plugins::FilePatch.define target: "app/javascript/app.js" do
          before_line(containing: "const old") { "// before" }
          replace_line containing: "const old = 0", with: "const renamed = 0"
          replace_block(from: "const start", to: "const stop") { "// block" }
          append_to_file { "// appended" }
          prepend_to_file { "// prepended" }
        end
      RUBY

      manager.sync!

      manifest = JSON.parse(tmpdir.join("tmp", "plugin_patches_test.json").read)
      ops = manifest["app/javascript/app.js"]
      by_type = ops.group_by { |o| o["type"] }

      expect(by_type.keys).to include(
        "before_line", "replace_line", "replace_block", "append_to_file", "prepend_to_file"
      )
      expect(by_type["replace_line"].first["content"]).to eq("const renamed = 0")
      expect(by_type["replace_block"].first).to include("from" => "const start", "to" => "const stop")
      expect(by_type["append_to_file"].first["content"]).to eq("// appended")
      expect(by_type["prepend_to_file"].first["content"]).to eq("// prepended")
    end
  end
end
