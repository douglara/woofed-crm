class Accounts::Apps::Chatwoots::SendMessage
  def self.call(chatwoot, conversation_id, content)
    request = Faraday.post(
      "#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/conversations/#{conversation_id}/messages",
      build_body(content),
      chatwoot.request_headers
    )
    return { ok: JSON.parse(request.body) }
  end

  def self.build_body(content)
    {
      "content": content,
    }
  end
end