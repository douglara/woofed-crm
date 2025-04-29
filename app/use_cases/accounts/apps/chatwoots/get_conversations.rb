class Accounts::Apps::Chatwoots::GetConversations
  def self.call(chatwoot, contact_id, inbox_id = nil)
    request = Faraday.get(
      "#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/contacts/#{contact_id}/conversations",
      {},
      chatwoot.request_headers
    )

    conversation_list = JSON.parse(request.body)['payload']

    return { ok: conversation_list } if inbox_id.nil?

    { ok: list_conversations_by_inbox(conversation_list, inbox_id) }
  end

  def self.list_conversations_by_inbox(conversation_list, inbox_id)
    conversation_list.select do |conversation|
      conversation['inbox_id'] == inbox_id.to_i
    end
  end
end
