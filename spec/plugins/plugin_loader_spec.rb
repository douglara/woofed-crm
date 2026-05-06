# frozen_string_literal: true

require "rails_helper"

RSpec.describe Plugins::PluginLoader do
  let(:tmpdir) { Rails.root.join("tmp", "plugin_loader_test_#{SecureRandom.hex(4)}") }

  before do
    Plugins::FilePatch.clear_registry!
    described_class.reset!
    FileUtils.mkdir_p(tmpdir)
  end

  after do
    Plugins::FilePatch.clear_registry!
    described_class.reset!
    FileUtils.rm_rf(tmpdir)
  end

  def create_file(relative_path, content)
    path = tmpdir.join(relative_path)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
    path
  end

  describe ".load_all!" do
    it "discovers plugins from the storage/plugins/ directory" do
      create_file("storage/plugins/example/plugin.rb", <<~RUBY)
        name "example"
        version "1.0.0"
        priority 10
      RUBY
      create_file("storage/plugins/example/app/models/dummy.rb", "class Dummy; end")

      described_class.load_all!(root: tmpdir)

      expect(described_class.loaded_plugins.size).to eq(1)
      plugin = described_class.loaded_plugins.first
      expect(plugin.name).to eq("example")
      expect(plugin.version).to eq("1.0.0")
      expect(plugin.priority).to eq(10)
    end

    it "sorts plugins by priority" do
      create_file("storage/plugins/beta/plugin.rb", <<~RUBY)
        name "beta"
        priority 20
      RUBY
      create_file("storage/plugins/beta/app/models/dummy.rb", "class Dummy; end")

      create_file("storage/plugins/alpha/plugin.rb", <<~RUBY)
        name "alpha"
        priority 10
      RUBY
      create_file("storage/plugins/alpha/app/models/dummy2.rb", "class Dummy2; end")

      described_class.load_all!(root: tmpdir)

      names = described_class.loaded_plugins.map(&:name)
      expect(names).to eq(%w[alpha beta])
    end

    it "skips folders without plugin.rb" do
      create_file("storage/plugins/no_manifest/app/models/thing.rb", "class Thing; end")

      described_class.load_all!(root: tmpdir)

      expect(described_class.loaded_plugins).to be_empty
    end

    it "handles missing storage/plugins/ directory gracefully" do
      expect { described_class.load_all!(root: tmpdir) }.not_to raise_error
      expect(described_class.loaded_plugins).to be_empty
    end

    it "defaults version to 0.0.0 and priority to 0" do
      create_file("storage/plugins/minimal/plugin.rb", 'name "minimal"')
      create_file("storage/plugins/minimal/app/models/dummy.rb", "class Dummy; end")

      described_class.load_all!(root: tmpdir)

      plugin = described_class.loaded_plugins.first
      expect(plugin.version).to eq("0.0.0")
      expect(plugin.priority).to eq(0)
    end
  end

  describe ".reset!" do
    it "clears loaded plugins" do
      create_file("storage/plugins/example/plugin.rb", 'name "example"')
      create_file("storage/plugins/example/app/models/dummy.rb", "class Dummy; end")

      described_class.load_all!(root: tmpdir)
      expect(described_class.loaded_plugins).not_to be_empty

      described_class.reset!
      expect(described_class.loaded_plugins).to be_empty
    end
  end
end
