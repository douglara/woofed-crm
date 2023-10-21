class Accounts::Apps::Chatwoots::GetConversations
  def self.call(chatwoot, contact_id, inbox_id)
    request = Faraday.post(
      "#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/conversations/filter?page=1",
      build_body(contact_id, inbox_id).to_json,
      chatwoot.request_headers
    )
    return { ok: JSON.parse(request.body)['payload'] }
  end

  def self.build_body(contact_id, inbox_id)
    {
      "payload":[
          {"attribute_key": "contact_id","attribute_model": "standard","filter_operator": "equal_to","values": ["#{contact_id}"],"query_operator": "and"},
          {"attribute_key": "inbox_id","filter_operator": "equal_to","values":[inbox_id],"custom_attribute_type": ""}
      ]    
    }
  end
end