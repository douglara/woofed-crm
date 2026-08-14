# frozen_string_literal: true

require "fileutils"
require "digest"
require "json"

module Plugins
  # Detects patch vs new file, syncs storage/build/.
  #
  # For every file in plugins/*/app/**, applies one rule:
  #   - app/<relative_path> exists  → patch (load DSL, apply over original, write to storage/build/)
  #   - app/<relative_path> absent  → new file (copy as-is to storage/build/)
  #
  # Fingerprint-based incremental build — only rebuilds files whose fingerprint has changed.
  class BuildManager
    attr_reader :root, :build_dir, :fingerprint_dir

    def initialize(root: Rails.root)
      @root = Pathname.new(root)
      @build_dir = @root.join("storage", "build")
      @fingerprint_dir = @root.join("tmp", "plugin_fingerprints")
    end

    # Full rebuild: wipe storage/build/ and recreate from scratch.
    def rebuild!
      FileUtils.rm_rf(build_dir)
      FileUtils.rm_rf(fingerprint_dir)
      sync!
    end

    # Incremental sync: only rebuild files whose fingerprint changed.
    def sync!
      FileUtils.mkdir_p(build_dir)
      FileUtils.mkdir_p(fingerprint_dir)

      Plugins::FilePatch.clear_registry!
      load_all_patch_files!
      process_all_plugin_files!
      remove_orphans!
      write_vite_patch_manifest!
    end

    # Preview the composed output for a single target (e.g. "app/models/contact.rb").
    def preview(target)
      original_path = root.join(target)
      return nil unless original_path.exist?

      original_content = original_path.read
      Plugins::FilePatch.apply(target, original_content)
    end

    # List all files currently in storage/build/.
    def status
      return [] unless build_dir.exist?

      Dir.glob(build_dir.join("**", "*"))
        .select { |f| File.file?(f) }
        .map { |f| Pathname.new(f).relative_path_from(build_dir).to_s }
        .sort
    end

    private

    # Discover active plugin directories from the database, ordered by priority.
    # No filesystem fallback: without readable, active Plugin records, nothing loads.
    def plugin_dirs
      return [] unless defined?(Plugin) && Plugin.table_exists?

      Plugin.active.order(:priority, :id).filter_map do |plugin|
        dir = root.join("storage", "plugins", plugin.id)
        dir if dir.exist?
      end
    end

    # Load all patch files whose relative path matches an existing app/ file and that
    # contain FilePatch DSL. This populates FilePatch.registry.
    # Files are detected by content (Plugins::FilePatch.define) rather than extension,
    # so .erb patch files containing DSL are also picked up.
    def load_all_patch_files!
      plugin_dirs.each do |plugin_dir|
        each_patchable_plugin_file(plugin_dir) do |plugin_file, relative|
          original = root.join(relative)
          next unless original.exist?
          next unless File.read(plugin_file).include?("Plugins::FilePatch.define")

          load plugin_file
        end
      end
    end

    # Process all plugin files: patch or copy.
    def process_all_plugin_files!
      seen_targets = Set.new

      plugin_dirs.each do |plugin_dir|
        each_patchable_plugin_file(plugin_dir) do |plugin_file, relative|
          original = root.join(relative)

          if original.exist?
            # Patch: apply DSL over original, write to storage/build/
            process_patch(relative, original) unless seen_targets.include?(relative)
            seen_targets << relative
          else
            # New file: copy as-is to storage/build/
            process_new_file(relative, plugin_file)
            seen_targets << relative
          end
        end
      end
    end

    # Yields [plugin_file_path, relative_path_from_project_root] for every file
    # that should be considered for patching or copying:
    #   - All files under plugin_dir/app/
    #   - Files under plugin_dir/config/ EXCEPT routes.rb (which is loaded separately)
    def each_patchable_plugin_file(plugin_dir)
      # app/ files
      plugin_app = plugin_dir.join("app")
      if plugin_app.exist?
        Dir.glob(plugin_app.join("**", "*")).each do |f|
          next unless File.file?(f)
          yield f, Pathname.new(f).relative_path_from(plugin_dir).to_s
        end
      end

      # config/ files — skip routes.rb (handled by PluginLoader)
      plugin_config = plugin_dir.join("config")
      if plugin_config.exist?
        Dir.glob(plugin_config.join("**", "*")).each do |f|
          next unless File.file?(f)
          relative = Pathname.new(f).relative_path_from(plugin_dir).to_s
          next if relative == "config/routes.rb"
          yield f, relative
        end
      end
    end

    def process_patch(relative, original)
      original_content = original.read
      fingerprint = compute_fingerprint(relative, original_content)
      target_path = build_dir.join(relative)

      return if up_to_date?(relative, fingerprint, target_path)

      composed = Plugins::FilePatch.apply(relative, original_content)
      FileUtils.mkdir_p(target_path.dirname)
      File.write(target_path, composed)
      save_fingerprint(relative, fingerprint)
    end

    def process_new_file(relative, source)
      source_content = File.read(source)
      fingerprint = Digest::SHA256.hexdigest(source_content)
      target_path = build_dir.join(relative)

      return if up_to_date?(relative, fingerprint, target_path)

      FileUtils.mkdir_p(target_path.dirname)
      FileUtils.cp(source, target_path)
      save_fingerprint(relative, fingerprint)
    end

    # Compute fingerprint from original content + all patch file contents.
    def compute_fingerprint(relative, original_content)
      parts = [original_content]

      plugin_dirs.each do |plugin_dir|
        patch_file = plugin_dir.join(relative)
        parts << File.read(patch_file) if patch_file.exist?
      end

      Digest::SHA256.hexdigest(parts.join("\0"))
    end

    def fingerprint_path(relative)
      fingerprint_dir.join(relative.gsub("/", "__") + ".sha256")
    end

    def fingerprint_unchanged?(relative, fingerprint)
      path = fingerprint_path(relative)
      path.exist? && path.read.strip == fingerprint
    end

    # A build output can only be skipped when the fingerprint matches AND the file is
    # still on disk. storage/build/ and tmp/plugin_fingerprints/ have independent
    # lifecycles (different volumes, tmp:clear, manual pruning), so a stale fingerprint
    # left behind by a wiped build would otherwise make every later sync skip the file
    # and boot the application without it.
    def up_to_date?(relative, fingerprint, target_path)
      fingerprint_unchanged?(relative, fingerprint) && target_path.exist?
    end

    def save_fingerprint(relative, fingerprint)
      path = fingerprint_path(relative)
      FileUtils.mkdir_p(path.dirname)
      File.write(path, fingerprint)
    end

    # Remove files in storage/build/ that no longer have a source in any plugin.
    def remove_orphans!
      return unless build_dir.exist?

      active_relatives = Set.new

      plugin_dirs.each do |plugin_dir|
        each_patchable_plugin_file(plugin_dir) do |_f, relative|
          active_relatives << relative
        end
      end

      Dir.glob(build_dir.join("**", "*")).each do |f|
        next unless File.file?(f)

        relative = Pathname.new(f).relative_path_from(build_dir).to_s
        unless active_relatives.include?(relative)
          FileUtils.rm(f)
          # Clean empty dirs
          dir = File.dirname(f)
          while dir != build_dir.to_s && Dir.empty?(dir)
            FileUtils.rmdir(dir)
            dir = File.dirname(dir)
          end
          # Remove fingerprint
          fp = fingerprint_path(relative)
          FileUtils.rm(fp) if fp.exist?
        end
      end
    end

    # Write a JSON manifest of JS/JSX/TS/TSX patches for the Vite plugin.
    def write_vite_patch_manifest!
      js_extensions = %w[.js .jsx .ts .tsx]
      manifest = {}

      Plugins::FilePatch.registry.each do |target, entries|
        ext = File.extname(target).downcase
        next unless js_extensions.include?(ext)

        patches_data = entries.sort_by { |e| e[:priority] }.flat_map do |entry|
          entry[:patch].operations.map do |op|
            serialize_operation(op)
          end
        end

        manifest[target] = patches_data unless patches_data.empty?
      end

      manifest_path = root.join("tmp", "plugin_patches_#{Rails.env}.json")
      File.write(manifest_path, JSON.pretty_generate(manifest))
    end

    def serialize_operation(op)
      data = { "type" => op.type.to_s }

      case op.type
      when :after_line, :before_line
        data["match"] = op.options[:containing]
        data["content"] = op.block.call.to_s
      when :replace_line
        data["match"] = op.options[:containing]
        data["content"] = op.options[:with]
      when :replace_block
        data["from"] = op.options[:from]
        data["to"] = op.options[:to]
        data["content"] = op.block.call.to_s
      when :append_to_file
        data["content"] = op.block.call.to_s
      when :prepend_to_file
        data["content"] = op.block.call.to_s
      end

      data
    end
  end
end
