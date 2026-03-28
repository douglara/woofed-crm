# frozen_string_literal: true

module Plugins
  # Loads plugins based on the plugins table (DB-first).
  #
  # Boot flow:
  #   1. Read active Plugin records from the database.
  #   2. Clone any that are missing locally (using github_url).
  #   3. Load manifests only for plugins that are both active in DB and present on disk.
  #   4. Sync storage/build/ via BuildManager.
  #   5. Update version/commit_sha metadata on existing Plugin records.
  #
  # Plugins NOT in the database are never loaded, regardless of what exists
  # under storage/plugins/.
  class PluginLoader
    PluginManifest = Struct.new(:name, :version, :priority, :path, keyword_init: true)

    class << self
      def loaded_plugins
        @loaded_plugins ||= []
      end

      def reset!
        @loaded_plugins = []
      end

      def load_all!(root: Rails.root)
        reset!
        newly_cloned = clone_missing_plugins!(root)
        discover_from_database!(root)
        load_plugin_routes!(root)
        sync_build!(root)
        update_plugin_metadata!

        # Restart so the next boot registers new migration paths / routes cleanly.
        schedule_restart!(root) if newly_cloned.any?
      end

      private

      # For each active Plugin record not installed locally:
      #   - clone from github_url (must be present)
      #   - if clone fails or URL is blank, mark as failed
      # Returns list of successfully cloned plugin names.
      def clone_missing_plugins!(root)
        return [] unless defined?(Plugin) && Plugin.table_exists?

        newly_cloned = []

        Plugin.active.each do |plugin_record|
          next if plugin_record.installed_locally?

          if plugin_record.github_url.present?
            Rails.logger.info "[PluginLoader] Cloning missing plugin '#{plugin_record.name}' from #{plugin_record.github_url}"
            plugins_dir = root.join("storage", "plugins")
            FileUtils.mkdir_p(plugins_dir)

            cloned = system("git", "clone", "--depth", "1", "--branch", "master",
                            plugin_record.github_url,
                            plugin_record.local_path.to_s)

            newly_cloned << plugin_record.name if cloned && plugin_record.installed_locally?
          end

          unless plugin_record.installed_locally?
            Rails.logger.error "[PluginLoader] Plugin '#{plugin_record.name}' could not be installed locally — marking as failed"
            plugin_record.update_columns(status: "failed")
          end
        end

        newly_cloned
      end

      # Build loaded_plugins from the DB: only active plugins that are installed locally.
      # Plugins on disk but NOT in the database are ignored entirely.
      def discover_from_database!(root)
        return unless defined?(Plugin) && Plugin.table_exists?

        Plugin.active.each do |plugin_record|
          unless plugin_record.installed_locally?
            Rails.logger.warn "[PluginLoader] Plugin '#{plugin_record.name}' is active in DB but missing locally — skipping"
            next
          end

          manifest_path = plugin_record.local_path.join("plugin.rb")
          unless manifest_path.exist?
            Rails.logger.warn "[PluginLoader] Plugin '#{plugin_record.name}' has no plugin.rb manifest — skipping"
            next
          end

          manifest = parse_manifest(manifest_path, plugin_record.local_path)
          loaded_plugins << manifest if manifest
        end

        loaded_plugins.sort_by!(&:priority)
      end

      # Update version and commit_sha on existing Plugin records from the loaded manifests.
      # Does NOT create new records — DB is the source of truth for what is installed.
      def update_plugin_metadata!
        return unless defined?(Plugin) && Plugin.table_exists?

        loaded_plugins.each do |manifest|
          Plugin.find_by(name: manifest.name)&.tap do |record|
            commit_sha = read_commit_sha(manifest.path)
            record.update_columns(version: manifest.version, commit_sha: commit_sha)
          end
        rescue => e
          Rails.logger.error "[PluginLoader] Failed to update metadata for '#{manifest.name}': #{e.message}"
        end
      end

      def schedule_restart!(root)
        Rails.logger.info "[PluginLoader] New plugin(s) cloned — scheduling restart to register migration paths"
        FileUtils.touch(root.join("tmp", "restart.txt"))
      end

      def read_commit_sha(plugin_dir)
        git_dir = plugin_dir.join(".git")
        return nil unless git_dir.exist?

        sha = `git -C #{plugin_dir} rev-parse HEAD 2>/dev/null`.strip
        sha.empty? ? nil : sha
      end

      def parse_manifest(manifest_path, plugin_dir)
        content = File.read(manifest_path)

        name     = content[/name\s+["'](.+?)["']/, 1]
        version  = content[/version\s+["'](.+?)["']/, 1] || "0.0.0"
        priority = content[/priority\s+(\d+)/, 1]&.to_i || 0

        return nil unless name

        PluginManifest.new(name: name, version: version, priority: priority, path: plugin_dir)
      end

      def load_plugin_routes!(root)
        loaded_plugins.each do |plugin|
          routes_file = plugin.path.join("config", "routes.rb")
          next unless routes_file.exist?

          # Routes are drawn in via the Rails router — see the initializer.
        end
      end

      def sync_build!(root)
        build_manager = Plugins::BuildManager.new(root: root)
        build_manager.sync!
      end
    end
  end
end
