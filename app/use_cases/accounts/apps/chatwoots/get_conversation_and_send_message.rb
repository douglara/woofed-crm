class Accounts::Apps::Chatwoots::GetConversationAndSendMessage
  def self.call(chatwoot, contact_id, inbox_id, event)
    conversation = Accounts::Apps::Chatwoots::FindOrCreateConversation.call(
      chatwoot, contact_id, inbox_id
    )[:ok]

    Accounts::Apps::Chatwoots::SendMessage.call(chatwoot, conversation['id'], event)
  end
end
