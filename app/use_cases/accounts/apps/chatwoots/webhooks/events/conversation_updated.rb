class Accounts::Apps::Chatwoots::Webhooks::Events::ConversationUpdated
  def self.call(chatwoot, webhook)
    contact = Accounts::Apps::Chatwoots::Webhooks::ImportContact.call(chatwoot, webhook['contact_inbox']['contact_id'])
    return { ok: contact }
  end
end