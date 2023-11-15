class Accounts::Apps::Chatwoots::SyncInboxes

  def self.call(chatwoot)
    inboxes_request = Faraday.get(
      "#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/inboxes",
      {},
      chatwoot.request_headers
    )

    chatwoot.update(inboxes: JSON.parse(inboxes_request.body)['payload'])
    return true
  end
end