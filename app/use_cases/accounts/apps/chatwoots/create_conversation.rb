class Accounts::Apps::Chatwoots::CreateConversation
  def self.call(chatwoot, contact_id, inbox_id)
    request = Faraday.post(
      "#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/conversations",
      build_body(contact_id, inbox_id).to_json,
      chatwoot.request_headers
    )
    return { ok: JSON.parse(request.body) }
  end

  def self.build_body(contact_id, inbox_id)
    {
      "inbox_id": inbox_id,
      "contact_id": contact_id,
    }
  end
end