class Accounts::Apps::Chatwoots::Webhooks::SendContact
  def self.call(chatwoot, contact)
    request = Faraday.post(
      "#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/contacts",
      build_body(contact),
      chatwoot.request_headers
    )
    response_body = JSON.parse(request.body) rescue {}
  
    if request.status == 200 && response_body['id'].present?
      return { ok: contact }
    else
      return { error: request.body }
    end
  end

  def self.build_body(contact)
    {
      "name": contact['full_name'],
      "email": contact['email'],
      "phone_number": contact['phone'],
      "custom_attributes": contact['custom_attributes']
    }.to_json
  end
end
