# frozen_string_literal: true

Rails.application.configure do
  config.good_job.preserve_job_records = true
  config.good_job.cleanup_discarded_jobs = true
  config.good_job.cleanup_preserved_jobs_before_seconds_ago = 7_200
  config.good_job.cleanup_interval_seconds = 600
  config.good_job.cleanup_interval_jobs = 100
  config.good_job.enable_cron = true

  config.good_job.cron = {
    evolution_api_refresh_status: {
      cron: '0 * * * *',
      class: 'Accounts::Apps::EvolutionApis::Instance::SessionsRefreshStatusJob'
    },
    apps_chatwoot_connection_refresh: {
      cron: '0 12 * * *',
      class: 'Apps::Chatwoot::Connection::RefreshJob'
    },
    webhook_status_refresh: {
      cron: '0 12 * * *',
      class: 'Webhook::Status::RefreshJob'
    }
  }
end

GoodJob::Engine.middleware.use Rack::Auth::Basic, 'Restricted Area' do |user, password|
  [user, password] == [ENV.fetch('MOTOR_AUTH_USERNAME', 'lovewoofed'), ENV.fetch('MOTOR_AUTH_PASSWORD', 'lovewoofed')]
end
