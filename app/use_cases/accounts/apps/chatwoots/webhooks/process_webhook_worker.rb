class Accounts::Apps::Chatwoots::Webhooks::ProcessWebhookWorker
  include Sidekiq::Worker

  sidekiq_options queue: :chatwoot_webhooks

  def perform(event)
    event_hash = JSON.parse(event)
    Accounts::Apps::Chatwoots::Webhooks::ProcessWebhook.call(event_hash)
  end
end