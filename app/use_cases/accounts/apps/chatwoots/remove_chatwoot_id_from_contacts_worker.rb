class Accounts::Apps::Chatwoots::RemoveChatwootIdFromContactsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :chatwoot_webhooks
  def perform(account_id)
    account = Account.find(account_id)
    Accounts::Apps::Chatwoots::RemoveChatwootIdFromContacts.call(account)
  end
end
    