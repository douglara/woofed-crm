class Accounts::Apps::Chatwoots::SendMessage
  def self.call(chatwoot, conversation_id, event)
    request = Faraday.post(
      "#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/conversations/#{conversation_id}/messages",
      build_body(event).to_json,
      request_headers(event, chatwoot)
    )
    { ok: JSON.parse(request.body) }
  end

  def self.build_body(event)
    if event.attachment.present?
      build_message_attachment(event)
    else
      build_message_text(event.content)
    end
  end

  def self.build_message_text(content)
    {
      "content": content
    }
  end

  def self.build_message_attachment(event)
    {
      "attachments[]": event.attachment.file.download,
      "content": event.content,
      "file_type": event.attachment.file_type
    }
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
