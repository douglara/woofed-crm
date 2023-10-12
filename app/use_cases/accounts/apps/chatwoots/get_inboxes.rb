class Accounts::Apps::Chatwoots::GetInboxes

  def self.call(chatwoot)
    inboxes_request = Faraday.get(
      "#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/inboxes",
      {},
      chatwoot.request_headers
    )
    return { ok: JSON.parse(inboxes_request.body)['payload'] }
  end
end