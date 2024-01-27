class Accounts::Apps::EvolutionApis::Webhooks::ProcessWebhookWorker
  include Sidekiq::Worker

  sidekiq_options queue: :evolution_api_webhooks

  def perform(event)
    event_hash = JSON.parse(event)
    Accounts::Apps::EvolutionApis::Webhooks::ProcessWebhook.call(event_hash)
  end
end
