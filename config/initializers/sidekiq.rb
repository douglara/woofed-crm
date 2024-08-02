require 'sidekiq'
require 'sidekiq/web'

redis_max_connections = 12

class RailsLoggerSidekiqServerMiddleware
  def call(worker, _job_options, _queue, &block)
    tags = [worker.class.name, worker.jid]
    Rails.logger.tagged(*tags, &block)
  end
end

Sidekiq.configure_client do |config|
  config.redis = {
    url: ENV['REDIS_URL'] || ENV['REDISCLOUD_URL'],
    size: redis_max_connections
  }
end

Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add RailsLoggerSidekiqServerMiddleware
  end

  config.death_handlers << lambda { |job, ex|
    Rails.logger.error("Error #{job['class']} #{job['jid']} just died with error #{ex.message}.")
    Rails.logger.error(job.inspect)
  }

  config.redis = {
    url: ENV['REDIS_URL'] || ENV['REDISCLOUD_URL'],
    size: redis_max_connections
  }
end

Sidekiq::Web.use(Rack::Auth::Basic) do |user, password|
  [user, password] == [ENV.fetch('MOTOR_AUTH_USERNAME') { 'lovewoofed' }, ENV.fetch('MOTOR_AUTH_PASSWORD') do
                                                                            'lovewoofed'
                                                                          end]
end
