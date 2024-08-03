class Accounts::Apps::Chatwoots::SyncChatwootWorker
  include Sidekiq::Worker
  sidekiq_options queue: :chatwoot_webhooks

  def perform(account_id, chatwoot_id)
    chatwoot = Apps::Chatwoot.find(chatwoot_id)
    account = Account.find(account_id)

    Accounts::Apps::Chatwoots::SyncImportContacts.new(chatwoot).call
    Accounts::Apps::Chatwoots::SyncExportContacts.call(account)
  end
end
