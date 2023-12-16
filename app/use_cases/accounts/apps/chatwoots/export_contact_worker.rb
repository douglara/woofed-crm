class Accounts::Apps::Chatwoots::ExportContactWorker
  include Sidekiq::Worker
  sidekiq_options queue: :chatwoot_webhooks

  def perform(chatwoot_id, contact_id)
    contact = Contact.find(contact_id)
    chatwoot = Apps::Chatwoot.find(chatwoot_id)
    Accounts::Apps::Chatwoots::ExportContact.call(chatwoot, contact)
  end
end
