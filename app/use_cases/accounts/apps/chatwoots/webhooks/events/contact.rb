class Accounts::Apps::Chatwoots::Webhooks::Events::Contact
  def self.call(chatwoot, webhook)
    return Accounts::Apps::Chatwoots::Webhooks::ImportContact.call(chatwoot, webhook['id'])
  end
end
