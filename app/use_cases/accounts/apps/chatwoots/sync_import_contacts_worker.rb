class Accounts::Apps::Chatwoots::SyncImportContactsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :chatwoot_webhooks

  def perform(chatwoot_id)
    chatwoot = Apps::Chatwoot.find(chatwoot_id)
    Accounts::Apps::Chatwoots::SyncImportContacts.new(chatwoot).call
  end
end
