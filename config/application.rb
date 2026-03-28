require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

## Load the specific APM agent
# We rely on DOTENV to load the environment variables
# We need these environment variables to load the specific APM agent
Dotenv::Rails.load

if ENV.fetch('NEW_RELIC_LICENSE_KEY', false).present?
  require 'newrelic-sidekiq-metrics'
  require 'newrelic_rpm'
end

if ENV.fetch('SENTRY_DSN', false).present?
  require 'sentry-ruby'
  require 'sentry-rails'
  require 'sentry-sidekiq'
end

require 'elastic-apm' if ENV.fetch('ELASTIC_APM_SECRET_TOKEN', false).present?

module WoofedCrm
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w(assets tasks))

    # Plugin system: prepend storage/build/app so patched files take precedence.
    build_app = root.join("storage", "build", "app")
    if build_app.exist?
      config.autoload_paths.unshift(build_app.join("models").to_s)
      config.eager_load_paths.unshift(build_app.join("models").to_s)

      config.autoload_paths.unshift(build_app.join("controllers").to_s)
      config.eager_load_paths.unshift(build_app.join("controllers").to_s)

      config.paths["app/views"].unshift(build_app.join("views").to_s)
      config.paths["app/controllers"].unshift(build_app.join("controllers").to_s)
      config.paths["app/helpers"].unshift(build_app.join("helpers").to_s)
    end

    # Plugin system: add plugin migration paths.
    plugins_dir = root.join("storage", "plugins")
    if plugins_dir.exist?
      plugins_dir.children.select(&:directory?).each do |plugin_dir|
        migrate_dir = plugin_dir.join("db", "migrate")
        config.paths["db/migrate"] << migrate_dir.to_s if migrate_dir.exist?
      end
    end

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Disable serving static files from the `/public` folder by default since
    # Apache or NGINX already handles this.
    config.public_file_server.enabled = true

    # Do not fallback to assets pipeline if a precompiled asset is missed.
    config.assets.compile = true
    config.serve_static_assets = true

    config.host = nil

    config.assets.css_compressor = nil
    config.active_storage.service_urls_expire_in = 1.hour

    Rails.application.default_url_options = { host: ENV['FRONTEND_URL'] }
    if ENV['FRONTEND_URL'].present? && ENV['FRONTEND_URL'].include?('https')
      Rails.application.default_url_options.merge!({ protocol: 'https' })
    elsif Rails.env.test?
      Rails.application.default_url_options.merge!({ protocol: 'http' })
    else
      Rails.application.default_url_options.merge!({ protocol: 'http', port: ENV['PORT'].to_i })
    end
    config.action_controller.default_url_options = Rails.application.default_url_options.dup
    config.action_mailer.default_url_options = Rails.application.default_url_options.dup
    Rails.application.routes.default_url_options = Rails.application.default_url_options.dup
  end
end
