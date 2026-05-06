# frozen_string_literal: true

require 'securerandom'

namespace :plugins do
  desc "Install a plugin from a public GitHub repository URL"
  task :install, [:url] => :environment do |_t, args|
    url = args[:url]
    abort "Usage: rails plugins:install[https://github.com/user/repo]" if url.blank?

    unless url.match?(%r{\Ahttps://github\.com/[\w.\-]+/[\w.\-]+(?:\.git)?\z})
      abort "Error: Only public GitHub HTTPS URLs are supported (https://github.com/user/repo)"
    end

    plugins_dir = Rails.root.join("storage", "plugins")
    FileUtils.mkdir_p(plugins_dir)

    # Clone to a temp path so we can read the manifest for the canonical name.
    tmp_name = "#{File.basename(url, ".git")}-tmp-#{SecureRandom.hex(4)}"
    tmp_path = plugins_dir.join(tmp_name)

    puts "[plugins:install] Cloning #{url}..."
    unless system("git", "clone", "--depth", "1", url, tmp_path.to_s)
      FileUtils.rm_rf(tmp_path)
      abort "Error: git clone failed. Check the URL and try again."
    end

    manifest_path = tmp_path.join("plugin.rb")
    unless manifest_path.exist?
      FileUtils.rm_rf(tmp_path)
      abort "Error: Repository does not contain a plugin.rb manifest. Removed."
    end

    content = File.read(manifest_path)
    plugin_name = content[/name\s+["'](.+?)["']/, 1]
    unless plugin_name
      FileUtils.rm_rf(tmp_path)
      abort "Error: plugin.rb does not define a name."
    end

    if Plugin.exists?(name: plugin_name)
      FileUtils.rm_rf(tmp_path)
      abort "Error: Plugin '#{plugin_name}' is already registered in the database."
    end

    plugin_path = plugins_dir.join(plugin_name)
    if plugin_path.exist?
      FileUtils.rm_rf(tmp_path)
      abort "Error: Directory storage/plugins/#{plugin_name} already exists."
    end

    FileUtils.mv(tmp_path.to_s, plugin_path.to_s)
    puts "[plugins:install] Cloned to storage/plugins/#{plugin_name}"

    Plugin.create!(name: plugin_name, github_url: url, status: "active")
    puts "[plugins:install] Plugin '#{plugin_name}' registered in database."

    puts "[plugins:install] Running boot to activate plugin..."
    Rake::Task["plugins:boot"].invoke

    puts "[plugins:install] Restarting application..."
    FileUtils.touch(Rails.root.join("tmp", "restart.txt"))

    puts "[plugins:install] Done! Plugin '#{plugin_name}' is now installed and active."
  end

  desc "Uninstall a plugin by name"
  task :uninstall, [:name] => :environment do |_t, args|
    name = args[:name]
    abort "Usage: rails plugins:uninstall[plugin_name]" if name.blank?

    plugin = Plugin.find_by(name: name)
    abort "Error: Plugin '#{name}' not found in the database." unless plugin

    puts "[plugins:uninstall] Removing plugin '#{name}'..."
    plugin.destroy!
    puts "[plugins:uninstall] Plugin record deleted from database."

    plugin_path = Rails.root.join("storage", "plugins", name)
    if plugin_path.exist?
      FileUtils.rm_rf(plugin_path)
      puts "[plugins:uninstall] Removed directory storage/plugins/#{name}"
    end

    puts "[plugins:uninstall] Rebuilding without plugin..."
    Rake::Task["plugins:boot"].invoke

    puts "[plugins:uninstall] Restarting application..."
    FileUtils.touch(Rails.root.join("tmp", "restart.txt"))

    puts "[plugins:uninstall] Done! Plugin '#{name}' has been removed."
  end

  desc "Full plugin boot: rebuild, migrate, and compile assets"
  task boot: :environment do
    puts "[plugins:boot] Rebuilding storage/build/..."
    manager = Plugins::BuildManager.new
    manager.rebuild!
    files = manager.status
    puts "[plugins:boot] Build complete. #{files.size} file(s) in storage/build/"

    puts "[plugins:boot] Running db:prepare (create + migrate)..."
    Rake::Task["db:prepare"].invoke

    js_patched = files.any? { |f| f.match?(/\.(js|jsx|ts|tsx)$/) }
    css_patched = files.any? { |f| f.end_with?(".css") }

    if js_patched || css_patched
      puts "[plugins:boot] Installing JS dependencies (yarn install)..."
      system("yarn install --frozen-lockfile 2>/dev/null || yarn install") || puts("[plugins:boot] Warning: yarn install failed")

      if Rails.env.production?
        puts "[plugins:boot] Compiling assets for production..."
        Rake::Task["assets:precompile"].invoke
      else
        puts "[plugins:boot] Development mode — Vite dev server handles assets."
      end
    else
      puts "[plugins:boot] No JS/CSS plugin files, skipping asset steps."
    end

    puts "[plugins:boot] Done."
  end

  desc "Wipe and recreate storage/build/ from scratch"
  task rebuild: :environment do
    puts "Rebuilding storage/build/..."
    manager = Plugins::BuildManager.new
    manager.rebuild!
    puts "Done. Files in storage/build/:"
    manager.status.each { |f| puts "  #{f}" }
  end

  desc "Print composed file after patches (e.g. rails plugins:preview[app/models/contact.rb])"
  task :preview, [:target] => :environment do |_t, args|
    target = args[:target]
    abort "Usage: rails plugins:preview[app/models/contact.rb]" unless target

    manager = Plugins::BuildManager.new
    result = manager.preview(target)

    if result
      puts result
    else
      abort "File not found: #{target}"
    end
  end

  desc "List all files currently in storage/build/"
  task status: :environment do
    manager = Plugins::BuildManager.new
    files = manager.status

    if files.empty?
      puts "storage/build/ is empty or does not exist."
    else
      puts "Files in storage/build/ (#{files.size}):"
      files.each { |f| puts "  #{f}" }
    end
  end

  desc "List all registered plugins and their status"
  task list: :environment do
    plugins = Plugin.order(:name)
    if plugins.empty?
      puts "No plugins registered."
    else
      plugins.each do |p|
        locally = p.installed_locally? ? "installed" : "MISSING locally"
        puts "  #{p.name} [#{p.status}] #{locally} — #{p.github_url}"
      end
    end
  end
end
