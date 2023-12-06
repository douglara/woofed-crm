class Accounts::Apps::Chatwoots::SearchContact
  def self.call(chatwoot, params)
    request = Faraday.get(
      "#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/contacts/search",
      build_body(params),
      chatwoot.request_headers
    )
    body = JSON.parse(request.body)

    return body['payload'].first if body['payload'].present?
    return { error: 'Contact not found' }
  end

  def self.build_body(content)
    {
    "q": content,
    }
  end
end
