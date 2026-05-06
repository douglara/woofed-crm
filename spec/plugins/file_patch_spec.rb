# frozen_string_literal: true

require "rails_helper"

RSpec.describe Plugins::FilePatch do
  before { described_class.clear_registry! }
  after  { described_class.clear_registry! }

  describe ".define" do
    it "registers a patch for the given target" do
      described_class.define(target: "app/models/contact.rb") do
        after_line containing: "class Contact" do
          "  include MyExtension"
        end
      end

      expect(described_class.registry["app/models/contact.rb"].size).to eq(1)
    end

    it "returns a FilePatch instance" do
      patch = described_class.define(target: "app/models/contact.rb") do
        after_line containing: "class Contact" do
          "  include MyExtension"
        end
      end

      expect(patch).to be_a(described_class)
      expect(patch.target).to eq("app/models/contact.rb")
    end

    it "accepts a priority" do
      described_class.define(target: "app/models/contact.rb", priority: 10) do
        after_line containing: "class Contact" do
          "  include Alpha"
        end
      end

      entry = described_class.registry["app/models/contact.rb"].first
      expect(entry[:priority]).to eq(10)
    end
  end

  describe ".patches_for" do
    it "returns patches sorted by priority" do
      described_class.define(target: "app/models/contact.rb", priority: 20) do
        after_line containing: "class Contact" do
          "  include Beta"
        end
      end

      described_class.define(target: "app/models/contact.rb", priority: 10) do
        after_line containing: "class Contact" do
          "  include Alpha"
        end
      end

      patches = described_class.patches_for("app/models/contact.rb")
      expect(patches.map(&:priority)).to eq([10, 20])
    end

    it "returns empty array for unknown targets" do
      expect(described_class.patches_for("app/unknown.rb")).to eq([])
    end
  end

  describe ".apply" do
    it "applies all registered patches for a target" do
      original = "class Contact < ApplicationRecord\nend\n"

      described_class.define(target: "app/models/contact.rb") do
        after_line containing: "class Contact" do
          "  include MyExtension"
        end
      end

      result = described_class.apply("app/models/contact.rb", original)
      expect(result).to include("include MyExtension")
      expect(result).to include("class Contact < ApplicationRecord")
    end

    it "returns original content when no patches registered" do
      original = "class Contact\nend\n"
      result = described_class.apply("app/models/contact.rb", original)
      expect(result).to eq(original)
    end
  end

  describe ".clear_registry!" do
    it "removes all registered patches" do
      described_class.define(target: "app/models/contact.rb") do
        after_line containing: "class Contact" do
          "  include MyExtension"
        end
      end

      described_class.clear_registry!
      expect(described_class.registry).to be_empty
    end
  end

  describe "DSL operations" do
    it "records after_line operations" do
      patch = described_class.define(target: "test.rb") do
        after_line containing: "marker" do
          "new line"
        end
      end

      expect(patch.operations.size).to eq(1)
      op = patch.operations.first
      expect(op.type).to eq(:after_line)
      expect(op.options[:containing]).to eq("marker")
    end

    it "records before_line operations" do
      patch = described_class.define(target: "test.rb") do
        before_line containing: "marker" do
          "new line"
        end
      end

      op = patch.operations.first
      expect(op.type).to eq(:before_line)
    end

    it "records replace_line operations" do
      patch = described_class.define(target: "test.rb") do
        replace_line containing: "old line", with: "new line"
      end

      op = patch.operations.first
      expect(op.type).to eq(:replace_line)
      expect(op.options[:with]).to eq("new line")
    end

    it "records replace_block operations" do
      patch = described_class.define(target: "test.rb") do
        replace_block from: "start", to: "end" do
          "replacement"
        end
      end

      op = patch.operations.first
      expect(op.type).to eq(:replace_block)
      expect(op.options[:from]).to eq("start")
      expect(op.options[:to]).to eq("end")
    end

    it "records append_to_file operations" do
      patch = described_class.define(target: "test.rb") do
        append_to_file do
          "appended content"
        end
      end

      op = patch.operations.first
      expect(op.type).to eq(:append_to_file)
    end

    it "records prepend_to_file operations" do
      patch = described_class.define(target: "test.rb") do
        prepend_to_file do
          "prepended content"
        end
      end

      op = patch.operations.first
      expect(op.type).to eq(:prepend_to_file)
    end
  end
end
