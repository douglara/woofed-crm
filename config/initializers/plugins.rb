# frozen_string_literal: true

# Load plugins and sync storage/build/ on boot.
# The build folder is the single mechanism for extending all file types.

Rails.application.config.after_initialize do
  next if defined?(Rails::Generators) # skip during generators

  Plugins::PluginLoader.load_all!

  # Load plugin locales into I18n.
  Plugins::PluginLoader.loaded_plugins.each do |plugin|
    locale_dir = plugin.path.join("config", "locales")
    if locale_dir.exist?
      I18n.load_path += Dir[locale_dir.join("**", "*.{rb,yml}")]
    end
  end
  I18n.reload!
end
