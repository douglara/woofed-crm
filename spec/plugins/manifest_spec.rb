# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Plugins::Manifest do
  let(:tmpdir) { Rails.root.join('tmp', "manifest_spec_#{SecureRandom.hex(4)}") }

  before { FileUtils.mkdir_p(tmpdir) }
  after  { FileUtils.rm_rf(tmpdir) }

  def write_manifest(content)
    path = tmpdir.join('plugin.rb')
    File.write(path, content)
    path
  end

  describe '.parse' do
    it 'reads name, version and priority from the manifest' do
      manifest = described_class.parse(write_manifest(<<~RUBY))
        name "example"
        version "1.2.0"
        priority 10
      RUBY

      expect(manifest).to have_attributes(
        name: 'example',
        version: '1.2.0',
        priority: 10,
        path: tmpdir.to_s
      )
    end

    it 'accepts single-quoted values' do
      manifest = described_class.parse(write_manifest("name 'single'"))

      expect(manifest.name).to eq('single')
    end

    it 'defaults version to 0.0.0 and priority to 0 when absent' do
      manifest = described_class.parse(write_manifest('name "minimal"'))

      expect(manifest.version).to eq('0.0.0')
      expect(manifest.priority).to eq(0)
    end

    it 'returns nil when the manifest has no name' do
      expect(described_class.parse(write_manifest('version "1.0.0"'))).to be_nil
    end
  end
end
