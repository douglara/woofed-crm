class Accounts::Apps::Chatwoots::GetConversationAndSendMessage
  def self.call(chatwoot, contact_id, inbox_id, content)
    conversation = Accounts::Apps::Chatwoots::FindOrCreateConversation.call(
      chatwoot, contact_id, inbox_id
    )[:ok]

    return Accounts::Apps::Chatwoots::SendMessage.call(chatwoot, conversation['id'], content)
  end
end