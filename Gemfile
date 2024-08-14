source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.3.4'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails', branch: 'main'
gem 'rails', '7.0.8.4'
# Rails 6.1.7.7 compatibility
gem 'loofah', '< 2.21.0'
# Use postgresql as the database for Active Record
gem 'pg', '~> 1.1'
# Use Puma as the app server
gem 'puma', '6.4.2'
# Use SCSS for stylesheets
gem 'sass-rails', '>= 6'
# Transpile app-like JavaScript. Read more: https://github.com/rails/webpacker
gem 'webpacker', '~> 5.0'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'hotwire-rails'
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.7'
# Use Redis adapter to run Action Cable in production
gem 'redis', '~> 4.0'
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# #-- for active storage --##
gem 'aws-sdk-s3', require: false
# original gem isn't maintained actively
gem 'azure-storage-blob', git: 'https://github.com/chatwoot/azure-storage-ruby', branch: 'chatwoot', require: false
gem 'google-cloud-storage', require: false
gem 'image_processing'

# Authentication
gem 'acts_as_list'
gem 'acts-as-taggable-on', '~> 9.0'
gem 'cocoon'
gem 'csv'
gem 'devise'
gem 'drb'
gem 'faraday'
gem 'faraday-follow_redirects'
gem 'good_job', '3.99.1'
gem 'html2text'
gem 'jsonb_accessor', '1.3.2'
gem 'json_csv'
gem 'jwt', '2.2.3'
gem 'motor-admin', '0.4.20'
gem 'pagy', '~> 3.5'
gem 'rails-i18n', '~> 7.0.0'
gem 'ransack', '4.1.1'
gem 'requestjs-rails'
gem 'sidekiq'
gem 'sidekiq-limit_fetch'
gem 'web-push'
gem 'wisper', '2.0.0'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.4', require: false

# #-- apm and error monitoring ---#
# loaded only when environment variables are set.
# ref application.rb
gem 'dotenv-rails'
gem 'down', '~> 5.0'
gem 'elastic-apm', require: false
gem 'highlight_io', require: false
gem 'june-analytics-ruby', require: false
gem 'neighbor'
gem 'newrelic_rpm', require: false
gem 'newrelic-sidekiq-metrics', require: false
gem 'pgvector'
gem 'rack-cors'
gem 'reverse_markdown'
gem 'sentry-rails', require: false
gem 'sentry-ruby', require: false
gem 'sentry-sidekiq', require: false
gem 'text_splitters'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'debug', '1.9.1'
  gem 'erb_lint', require: false
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'rspec-rails', '~> 6.0.0'
  gem 'rubocop', require: false
  gem 'ruby-lsp'
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '~> 4.2'
  # Display performance information such as SQL time and flame graphs for each request in your browser.
  # Can be configured to work on production as well see: https://github.com/MiniProfiler/rack-mini-profiler/blob/master/README.md
  gem 'listen', '~> 3.3'
  gem 'rack-mini-profiler', '~> 2.0'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'annotate'
  gem 'htmlbeautifier'
  gem 'spring'
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '>= 3.26'
  gem 'selenium-webdriver'
  # Easy installation and use of web drivers to run system tests with browsers
  gem 'rexml', '3.3.2'
  gem 'simplecov', require: false
  gem 'simplecov_json_formatter', require: false
  gem 'vcr'
  gem 'webdrivers'
  gem 'webmock'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

gem 'tailwindcss-rails', '~> 2.0'

gem 'opentelemetry-exporter-otlp', '~> 0.26.1'
gem 'opentelemetry-instrumentation-all', '~> 0.50.1'
gem 'opentelemetry-sdk', '~> 1.3'
