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

  if ENV['PREVIEW_APP'].present?
    @activity_kind_whatsapp ||= ActivityKind.find_by_key('whatsapp')
    Faraday.get("#{@activity_kind_whatsapp['settings']['endpoint_url']}")  
  end
  FlowItems::ActivitiesKinds::WpConnect::Connection::StartAll.call()
end

Sidekiq::Web.use(Rack::Auth::Basic) do |user, password|
  [user, password] == [ENV.fetch('SIDEKIQ_USER'){ 'user' } , ENV.fetch('SIDEKIQ_PASSWORD'){ 'password' }]
end
