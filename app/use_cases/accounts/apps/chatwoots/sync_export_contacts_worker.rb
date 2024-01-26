class Accounts::Apps::Chatwoots::SyncExportContactsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :chatwoot_webhooks
  def perform(account_id)
    account = Account.find(account_id)
    Accounts::Apps::Chatwoots::SyncExportContacts.call(account)
  end
end
