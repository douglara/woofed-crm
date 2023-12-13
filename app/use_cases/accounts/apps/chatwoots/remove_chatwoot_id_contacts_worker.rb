class Accounts::Apps::Chatwoots::RemoveChatwootIdContactsWorker
    include Sidekiq::Worker
    sidekiq_options queue: :chatwoot_webhooks
    def perform(account_id)
      account = Account.find(account_id)
      Accounts::Apps::Chatwoots::RemoveChatwootIdContacts.call(account)
    end
  end
    