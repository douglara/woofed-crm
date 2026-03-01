# frozen_string_literal: true

require 'pathname'
require_relative 'plugins/code_prepend'

module Plugins
  class << self
    include CodePrepend

    # Phase 1: Call from config/application.rb BEFORE class Application
    # Sets up CodePrepend
    def setup!
      puts('Run plugins setup')
      setup_code_prepend!
    end

    # Phase 2: Call from config/application.rb AFTER class Application
    # Configure prepending hook
    def setup_prepend_in_autoloader
      return unless extensions.any?

      Rails.autoloaders.main.on_load do |cpath, klass, _abspath|
        apply_extensions(cpath, klass) if has_extension_for?(cpath)
      end
    end

    # Phase 3: Load plugins things
    def setup_before_initialize!
      load_migrations
      load_locales
    end

    # Phase 4: Call from config.after_initialize hook
    # Installs ActionView Moneky Patch and loads routes
    def setup_after_initialize!
      # Install ActionView hook for view injections
      load_actionview_monkey_patch! if CodeInjections.view_injections.any?

      # Load plugin routes
      load_routes
    end

    # Returns all plugin paths (used by Gemfile for dynamic loading)
    def plugins
      @plugins ||= find_plugins
    end

    private

    # Load migrations from all plugins
    def load_migrations
      plugins.each do |plugin_path|
        migrate_path = plugin_path.join('db', 'migrate')
        Rails.application.config.paths['db/migrate'] << migrate_path if migrate_path.exist?
      end
    end

    # Load locale files from all plugins
    def load_locales
      plugins.each do |plugin_path|
        locales_path = plugin_path.join('config', 'locales')
        Rails.application.config.i18n.load_path += Dir[locales_path.join('**', '*.yml')] if locales_path.exist?
      end
    end

    # Load routes from all plugins
    def load_routes
      plugins.each do |plugin_path|
        routes_file = plugin_path.join('config', 'routes.rb')
        load routes_file if routes_file.exist?
      end
    end

    def find_plugins
      plugins_dir = rails_root.join('plugins')
      return [] unless plugins_dir.exist?

      Dir[plugins_dir.join('*')].map { |path| Pathname.new(path) }.select(&:directory?)
    end

    def rails_root
      Pathname.new(File.expand_path('..', __dir__))
    end

    def load_zeitwerk_monkey_patch!
      require_relative 'core_extensions/zeitwerk/loader/code_injections'
      Zeitwerk::Loader.prepend CoreExtensions::Zeitwerk::Loader::CodeInjections
    end

    def load_actionview_monkey_patch!
      require_relative 'core_extensions/action_view/template/code_injections'
      ActionView::Template.prepend CoreExtensions::ActionView::Template::CodeInjections
    end
  end
end
