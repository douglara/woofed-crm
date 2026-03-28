# frozen_string_literal: true

require "rails_helper"

RSpec.describe Plugins::Adapters::TextLine do
  before { Plugins::FilePatch.clear_registry! }
  after  { Plugins::FilePatch.clear_registry! }

  let(:original) do
    <<~RUBY
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
  end

  describe "after_line" do
    it "inserts content after the matching line" do
      patch = Plugins::FilePatch.define(target: "app/models/contact.rb") do
        after_line containing: "class Contact < ApplicationRecord" do
          "  include Plugins::Example::ContactExtension"
        end
      end

      result = patch.apply_to(original)
      lines = result.lines.map(&:chomp)

      idx = lines.index { |l| l.include?("class Contact < ApplicationRecord") }
      expect(lines[idx + 1]).to include("include Plugins::Example::ContactExtension")
    end

    it "inserts multiline content" do
      patch = Plugins::FilePatch.define(target: "test.rb") do
        after_line containing: "class Contact" do
          "  include Alpha\n  include Beta"
        end
      end

      result = patch.apply_to(original)
      expect(result).to include("include Alpha")
      expect(result).to include("include Beta")
    end
  end

  describe "before_line" do
    it "inserts content before the matching line" do
      patch = Plugins::FilePatch.define(target: "test.rb") do
        before_line containing: "belongs_to :account" do
          "  has_many :things"
        end
      end

      result = patch.apply_to(original)
      lines = result.lines.map(&:chomp)

      idx = lines.index { |l| l.include?("belongs_to :account") }
      expect(lines[idx - 1]).to include("has_many :things")
    end
  end

  describe "replace_line" do
    it "replaces the matching line" do
      patch = Plugins::FilePatch.define(target: "test.rb") do
        replace_line containing: "ROLES = %w[admin user]",
                     with: "  ROLES = %w[admin user example_role]"
      end

      result = patch.apply_to(original)
      expect(result).to include("ROLES = %w[admin user example_role]")
      expect(result).not_to include("ROLES = %w[admin user]\n")
    end
  end

  describe "replace_block" do
    it "replaces content between start and end markers" do
      content_with_markers = <<~ERB
        <div>
          <%# plugin:example:start %>
          <%# plugin:example:end %>
        </div>
      ERB

      patch = Plugins::FilePatch.define(target: "test.erb") do
        replace_block from: "<%# plugin:example:start %>",
                      to: "<%# plugin:example:end %>" do
          "  <section>replaced content</section>"
        end
      end

      result = patch.apply_to(content_with_markers)
      expect(result).to include("<section>replaced content</section>")
      expect(result).not_to include("plugin:example:start")
      expect(result).not_to include("plugin:example:end")
    end

    it "raises when end marker not found" do
      content = "start\nno end marker\n"

      patch = Plugins::FilePatch.define(target: "test.rb") do
        replace_block from: "start", to: "MISSING_END" do
          "replacement"
        end
      end

      expect { patch.apply_to(content) }.to raise_error(Plugins::FilePatch::PatchError, /MISSING_END/)
    end
  end

  describe "append_to_file" do
    it "appends content at the end" do
      patch = Plugins::FilePatch.define(target: "test.rb") do
        append_to_file do
          "# appended"
        end
      end

      result = patch.apply_to(original)
      expect(result.strip.end_with?("# appended")).to be true
    end
  end

  describe "prepend_to_file" do
    it "prepends content at the beginning" do
      patch = Plugins::FilePatch.define(target: "test.rb") do
        prepend_to_file do
          "# prepended"
        end
      end

      result = patch.apply_to(original)
      expect(result.start_with?("# prepended")).to be true
    end
  end

  describe "error handling" do
    it "raises PatchError when containing string not found" do
      patch = Plugins::FilePatch.define(target: "test.rb") do
        after_line containing: "NONEXISTENT LINE" do
          "new content"
        end
      end

      expect { patch.apply_to(original) }.to raise_error(
        Plugins::FilePatch::PatchError, /NONEXISTENT LINE/
      )
    end
  end

  describe "combined operations" do
    it "applies multiple operations in order" do
      patch = Plugins::FilePatch.define(target: "app/models/contact.rb") do
        after_line containing: "class Contact < ApplicationRecord" do
          "  include Plugins::Example::ContactExtension"
        end

        replace_line containing: "ROLES = %w[admin user]",
                     with: "  ROLES = %w[admin user example_role]"
      end

      result = patch.apply_to(original)
      expect(result).to include("include Plugins::Example::ContactExtension")
      expect(result).to include("ROLES = %w[admin user example_role]")
    end
  end

  describe "CSS files" do
    let(:css_content) do
      <<~CSS
        :root {
          --primary: #3b82f6;
          --danger:  #ef4444;
        }

        .user-card {
          padding: 1rem;
          background: white;
        }
      CSS
    end

    it "patches CSS files correctly" do
      patch = Plugins::FilePatch.define(target: "app/assets/stylesheets/app.css") do
        after_line containing: "--danger:  #ef4444;" do
          "  --example-color: #8b5cf6;"
        end

        append_to_file do
          <<~CSS

            /* example plugin */
            .example-badge {
              background: var(--example-color);
            }
          CSS
        end
      end

      result = patch.apply_to(css_content)
      expect(result).to include("--example-color: #8b5cf6;")
      expect(result).to include(".example-badge")
    end
  end
end
