require 'sidekiq'
require 'sidekiq/web'

redis_max_connections = 12

Sidekiq.configure_client do |config|
  config.redis = {
      url: ENV['REDIS_URL'] || ENV['REDISCLOUD_URL'],
      size: redis_max_connections
  }
end


Sidekiq.configure_server do |config|
  config.redis = {
    url: ENV['REDIS_URL'] || ENV['REDISCLOUD_URL'],
    size: redis_max_connections
  }
end

Sidekiq::Web.use(Rack::Auth::Basic) do |user, password|
  [user, password] == [ENV.fetch('SIDEKIQ_USER'){ 'user' } , ENV.fetch('SIDEKIQ_PASSWORD'){ 'password' }]
end
