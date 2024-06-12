Rails.application.configure do
  config.good_job.enable_cron = true
  config.good_job.cron = {
    wpp_connect_refresh_status: { cron: '*/5 * * * *',
                                  class: 'Accounts::Apps::WppConnects::Connections::RefreshStatusJob' },
    evolution_api_refresh_status: { cron: '0 * * * *',
                                    class: 'Accounts::Apps::EvolutionApis::Instance::SessionsRefreshStatusJob' }
  }
end
GoodJob::Engine.middleware.use Rack::Auth::Basic, 'Restricted Area' do |user, password|
  [user, password] == [ENV.fetch('MOTOR_AUTH_USERNAME') { 'user' }, ENV.fetch('MOTOR_AUTH_PASSWORD') { 'password' }]
end
