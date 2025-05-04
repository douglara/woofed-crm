class Apps::EvolutionApi::Webhooks::ProcessWebhookWorker
  include Sidekiq::Worker

  sidekiq_options queue: :evolution_api_webhooks

  def perform(event)
    event_hash = JSON.parse(event)
    Apps::EvolutionApi::Webhooks::ProcessWebhook.call(event_hash)
  end
end
