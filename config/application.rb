require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module WoofedCrm
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    if Rails.env.production?
      Rails.application.routes.default_url_options = { host: ENV['HOST_URL'], protocol: 'https' }
    elsif Rails.env.development?
      Rails.application.routes.default_url_options = { host: ENV['HOST_URL'], protocol: 'http' }
    end

    # Disable serving static files from the `/public` folder by default since
    # Apache or NGINX already handles this.
    config.public_file_server.enabled = true

    # Do not fallback to assets pipeline if a precompiled asset is missed.
    config.assets.compile = true
    config.serve_static_assets = true
  end
end
