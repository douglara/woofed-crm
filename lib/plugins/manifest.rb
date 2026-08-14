# frozen_string_literal: true

module Plugins
  # Parses a plugin's `plugin.rb` manifest.
  #
  # Manifest format:
  #   name "example"
  #   version "1.0.0"
  #   priority 10
  #
  # Defaults: version → "0.0.0", priority → 0.
  # Returns nil when the manifest has no `name`.
  class Manifest
    Parsed = Struct.new(:name, :version, :priority, :path, keyword_init: true)

    def self.parse(manifest_path)
      content = File.read(manifest_path)

      name = content[/name\s+["'](.+?)["']/, 1]
      return nil unless name

      version  = content[/version\s+["'](.+?)["']/, 1] || "0.0.0"
      priority = content[/priority\s+(\d+)/, 1]&.to_i || 0

      Parsed.new(
        name: name,
        version: version,
        priority: priority,
        path: File.dirname(manifest_path)
      )
    end
  end
end
