class Accounts::Apps::Chatwoots::SendMessage
  def self.call(chatwoot, conversation_id, event)
    if event.attachment.present?
      send_message_with_attachment(chatwoot, conversation_id, event)
    else
      send_message_without_attachment(chatwoot, conversation_id, event)
    end
  end

  def self.send_message_with_attachment(chatwoot, conversation_id, event)
    require 'uri'
    require 'net/http'

    url = URI("#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/conversations/#{conversation_id}/messages")

    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true

    request = Net::HTTP::Post.new(url)
    request['api_access_token'] = chatwoot.chatwoot_user_token
    form_data = [['attachments[]', event.attachment.file_download],
                 ['content', event.generate_content_hash('content', event.content)['content'].to_s]]
    request.set_form form_data, 'multipart/form-data'
    response = https.request(request)
    { ok: JSON.parse(response.read_body) }
  end

  def self.send_message_without_attachment(chatwoot, conversation_id, event)
    request = Faraday.post(
      "#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/conversations/#{conversation_id}/messages",
      build_body(event).to_json,
      request_headers(event, chatwoot)
    )
    { ok: JSON.parse(request.body) }
  end

  def self.build_body(event)
    event.generate_content_hash('content', event.content)
  end

  def self.request_headers(event, chatwoot)
    if event.attachment.present?
      { 'api_access_token': chatwoot.chatwoot_user_token.to_s,
        'Content-Type': 'multipart/form-data; boundary=----WebKitFormBoundary' }
    else
      chatwoot.request_headers
    end
  end
end
