class Accounts::Apps::Chatwoots::Webhooks::SendContact
  def self.call(chatwoot, contact)
    request_body = {
      "name": contact['full_name'],
      "email": contact['email'],
      "phone_number": contact['phone'],
      # "avatar": "string",
      # "avatar_url": "string",
      # "identifier": "string",
      "custom_attributes": contact['custom_attributes']
      }
    request = Faraday.post("#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/contacts",
    request_body.to_json,
    chatwoot.request_headers
    )
    byebug
    return { ok: contact }
  end
end
