# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Plugin system integration", type: :integration do
  let(:tmpdir) { Rails.root.join("tmp", "plugin_integration_test_#{SecureRandom.hex(4)}") }
  let(:manager) { Plugins::BuildManager.new(root: tmpdir) }

  before do
    Plugins::FilePatch.clear_registry!
    FileUtils.mkdir_p(tmpdir)
  end

  after do
    Plugins::FilePatch.clear_registry!
    FileUtils.rm_rf(tmpdir)
  end

  def create_file(relative_path, content)
    path = tmpdir.join(relative_path)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
    path
  end

  describe "full Ruby model patch scenario" do
    it "produces the expected composed output from the spec" do
      create_file("app/models/contact.rb", <<~RUBY)
        class Contact < ApplicationRecord
          include Devise::JWT

          ROLES = %w[admin user]

          belongs_to :account
          validates :email, presence: true

          def display_name
            "\#{first_name} \#{last_name}"
          end
        end
      RUBY

      create_file("storage/plugins/example/plugin.rb", 'name "example"')
      create_file("storage/plugins/example/app/models/contact.rb", <<~RUBY)
        Plugins::FilePatch.define target: "app/models/contact.rb" do
          after_line containing: "class Contact < ApplicationRecord" do
            "  include Plugins::Example::ContactExtension"
          end

          replace_line containing: "ROLES = %w[admin user]",
                       with: "  ROLES = %w[admin user example_role]"
        end
      RUBY

      manager.sync!

      built = tmpdir.join("storage/build/app/models/contact.rb")
      content = built.read
      lines = content.lines.map(&:rstrip)

      # Verify the include is on the line after class declaration
      class_idx = lines.index { |l| l.include?("class Contact < ApplicationRecord") }
      expect(lines[class_idx + 1]).to include("include Plugins::Example::ContactExtension")

      # Verify ROLES was replaced
      expect(content).to include("ROLES = %w[admin user example_role]")
      expect(content).not_to match(/ROLES = %w\[admin user\]\s*$/)

      # Verify original was NOT modified
      original = tmpdir.join("app/models/contact.rb")
      expect(original.read).to include("ROLES = %w[admin user]")
      expect(original.read).not_to include("example_role")
    end
  end

  describe "full ERB view patch scenario" do
    it "produces the expected composed output" do
      create_file("app/views/users/show.html.erb", <<~ERB)
        <div class="user-card">
          <h1 class="user-name"><%= @user.name %></h1>
          <%= render "shared/avatar" %>

          <%# plugin:example:start %>
          <%# plugin:example:end %>
        </div>
      ERB

      create_file("storage/plugins/example/plugin.rb", 'name "example"')
      create_file("storage/plugins/example/app/views/users/show.html.erb", <<~RUBY)
        Plugins::FilePatch.define target: "app/views/users/show.html.erb" do
          after_line containing: '<h1 class="user-name">' do
            <<~ERB
              <% if @user.example_active? %>
                <%= render "example/badge", user: @user %>
              <% end %>
            ERB
          end

          replace_block from: "<%# plugin:example:start %>",
                        to:   "<%# plugin:example:end %>" do
            <<~ERB
              <section class="example-panel">
                <%= render "example/full_panel", user: @user %>
              </section>
            ERB
          end
        end
      RUBY

      manager.sync!

      built = tmpdir.join("storage/build/app/views/users/show.html.erb")
      content = built.read

      expect(content).to include("example_active?")
      expect(content).to include("example/badge")
      expect(content).to include("example-panel")
      expect(content).not_to include("plugin:example:start")
    end
  end

  describe "full JSX component patch scenario" do
    it "produces the expected composed output" do
      create_file("app/javascript/pages/UserProfile.jsx", <<~JSX)
        import React, { useState } from "react"
        import Avatar from "@/components/Avatar"

        export default function UserProfile({ user }) {
          const [tab, setTab] = useState("info")

          return (
            <div className="user-profile">
              <h1 className="user-name">{user.name}</h1>

              <div className="tabs">
                <button onClick={() => setTab("info")}>Info</button>
                {/* plugin:tabs */}
              </div>

              <div className="tab-content">
                {tab === "info" && <InfoTab user={user} />}
                {/* plugin:tab-content */}
              </div>
            </div>
          )
        }
      JSX

      create_file("storage/plugins/example/plugin.rb", 'name "example"')
      create_file("storage/plugins/example/app/javascript/pages/UserProfile.jsx", <<~RUBY)
        Plugins::FilePatch.define target: "app/javascript/pages/UserProfile.jsx" do
          after_line containing: 'import Avatar from "@/components/Avatar"' do
            'import ExampleBadge from "@/components/ExampleBadge"'
          end

          after_line containing: "{/* plugin:tabs */}" do
            '        <button onClick={() => setTab("example")}>Example</button>'
          end

          after_line containing: "{/* plugin:tab-content */}" do
            '        {tab === "example" && <ExampleBadge userId={user.id} />}'
          end
        end
      RUBY

      manager.sync!

      built = tmpdir.join("storage/build/app/javascript/pages/UserProfile.jsx")
      content = built.read

      expect(content).to include('import ExampleBadge from "@/components/ExampleBadge"')
      expect(content).to include('setTab("example")}>Example</button>')
      expect(content).to include('tab === "example" && <ExampleBadge userId={user.id} />')
    end
  end

  describe "full CSS patch scenario" do
    it "produces the expected composed output" do
      create_file("app/assets/stylesheets/app.css", <<~CSS)
        :root {
          --primary: #3b82f6;
          --danger:  #ef4444;
        }

        .user-card {
          padding: 1rem;
          background: white;
        }
      CSS

      create_file("storage/plugins/example/plugin.rb", 'name "example"')
      create_file("storage/plugins/example/app/assets/stylesheets/app.css", <<~RUBY)
        Plugins::FilePatch.define target: "app/assets/stylesheets/app.css" do
          after_line containing: "--danger:  #ef4444;" do
            "  --example-color: #8b5cf6;"
          end

          append_to_file do
            <<~CSS

              /* example plugin */
              .example-badge {
                background: var(--example-color);
                border-radius: 9999px;
              }
            CSS
          end
        end
      RUBY

      manager.sync!

      built = tmpdir.join("storage/build/app/assets/stylesheets/app.css")
      content = built.read

      expect(content).to include("--example-color: #8b5cf6;")
      expect(content).to include(".example-badge")
      expect(content).to include("border-radius: 9999px")
    end
  end

  describe "new file copying" do
    it "copies new files as-is without modification" do
      new_file_content = <<~RUBY
        module Plugins
          module Example
            module ContactExtension
              extend ActiveSupport::Concern

              included do
                has_many :example_records
              end
            end
          end
        end
      RUBY

      create_file("storage/plugins/example/plugin.rb", 'name "example"')
      create_file("storage/plugins/example/app/models/contact_extension.rb", new_file_content)

      manager.sync!

      built = tmpdir.join("storage/build/app/models/contact_extension.rb")
      expect(built).to exist
      expect(built.read).to eq(new_file_content)
    end
  end

  describe "two plugins patching the same file" do
    it "applies patches in priority order so beta can use alpha's lines as anchors" do
      create_file("app/javascript/pages/UserProfile.jsx", <<~JSX)
        import React from "react"
        import Avatar from "@/components/Avatar"

        export default function UserProfile() { return <div /> }
      JSX

      create_file("storage/plugins/alpha/plugin.rb", 'name "alpha"')
      create_file("storage/plugins/alpha/app/javascript/pages/UserProfile.jsx", <<~RUBY)
        Plugins::FilePatch.define target: "app/javascript/pages/UserProfile.jsx", priority: 10 do
          after_line containing: 'import Avatar from "@/components/Avatar"' do
            'import AlphaBadge from "@/components/AlphaBadge"'
          end
        end
      RUBY

      create_file("storage/plugins/beta/plugin.rb", 'name "beta"')
      create_file("storage/plugins/beta/app/javascript/pages/UserProfile.jsx", <<~RUBY)
        Plugins::FilePatch.define target: "app/javascript/pages/UserProfile.jsx", priority: 20 do
          after_line containing: 'import AlphaBadge from "@/components/AlphaBadge"' do
            'import BetaBadge from "@/components/BetaBadge"'
          end
        end
      RUBY

      manager.sync!

      built = tmpdir.join("storage/build/app/javascript/pages/UserProfile.jsx")
      content = built.read

      expect(content).to include("import AlphaBadge")
      expect(content).to include("import BetaBadge")

      lines = content.lines.map(&:strip)
      alpha_idx = lines.index("import AlphaBadge from \"@/components/AlphaBadge\"")
      beta_idx = lines.index("import BetaBadge from \"@/components/BetaBadge\"")
      expect(alpha_idx).to be < beta_idx
    end
  end
end
