# frozen_string_literal: true

Rails.application.configure do
  config.good_job.enable_cron = true
  config.good_job.cron = {
    evolution_api_refresh_status: { cron: '0 * * * *',
                                    class: 'Apps::EvolutionApi::Instance::SessionsRefreshStatusJob' }
  }
end

GoodJob::Engine.middleware.use Rack::Auth::Basic, 'Restricted Area' do |user, password|
  [user, password] == [ENV.fetch('MOTOR_AUTH_USERNAME', 'lovewoofed'), ENV.fetch('MOTOR_AUTH_PASSWORD', 'lovewoofed')]
end
