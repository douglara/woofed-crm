class Accounts::Apps::Chatwoots::Webhooks::SendContactWorker
    include Sidekiq::Worker

    sidekiq_options queue: :chatwoot_webhooks
    

    def perform(chatwoot_id, contact_json)
        contact = JSON.parse(contact_json)
        chatwoot = Apps::Chatwoot.find(chatwoot_id)
        Accounts::Apps::Chatwoots::Webhooks::SendContact.call(chatwoot, contact)
    end
end