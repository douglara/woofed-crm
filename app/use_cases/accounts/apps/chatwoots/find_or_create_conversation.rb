class Accounts::Apps::Chatwoots::FindOrCreateConversation
  def self.call(chatwoot, contact_id, inbox_id)
    conversations = Accounts::Apps::Chatwoots::GetConversations.call(
      chatwoot, contact_id, inbox_id
    )

    if conversations.dig(:ok, 0, 'id').present?
      return { ok: conversations.dig(:ok, 0) }
    else
      return Accounts::Apps::Chatwoots::CreateConversation.call(
        chatwoot, contact_id, inbox_id)
    end
  end
end