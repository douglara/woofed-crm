class Accounts::Apps::Chatwoots::Webhooks::Events::Contact
  def self.call(chatwoot, webhook)
    contact = Accounts::Apps::Chatwoots::Webhooks::ImportContact.call(chatwoot, webhook['id'])
    return { ok: contact }
  end
end