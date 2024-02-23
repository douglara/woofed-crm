class Accounts::Apps::Chatwoots::Webhooks::ImportMessage
  require 'open-uri'

  def self.call(chatwoot, contact, webhook)
    message = get_or_import_message(chatwoot, contact, webhook)
    if should_import_other_attachment?(webhook)
      Accounts::Apps::Chatwoots::Webhooks::ImportAttachments(chatwoot, contact, webhook)
    end
    { ok: message }
  end

  def self.get_or_import_message(chatwoot, contact, webhook)
    message = contact.events.where(
      '? <@ additional_attributes', { chatwoot_id: webhook['conversation']['messages'].first['id'] }.to_json
    ).first

    message = import_message(chatwoot, contact, webhook) if message.nil?
    message
  end

  def self.import_message(chatwoot, contact, webhook)
    message = contact.events.new(
      account: chatwoot.account,
      kind: 'chatwoot_message',
      from_me: is_from_me?(webhook),
      contact: contact,
      content: webhook['content'],
      done: true,
      done_at: webhook['created_at'],
      app: chatwoot
    )

    message.additional_attributes.merge!({ 'chatwoot_id' => webhook['conversation']['messages'].first['id'] })
    import_attachment(message, webhook['attachments'].first) if webhook['attachments'].present?
    message.save
    message
  end

  def self.import_attachment(event, attachment_params)
    downloaded_file = URI.open(attachment_params['data_url'])
    attachment = event.build_attachment(
      file_type: attachment_params['file_type']
    )
    attachment.file.attach(io: downloaded_file,
      filename: "attachment_#{attachment_params['file_type']}_#{event.additional_attributes['chatwoot_id']}")
  end

  def self.should_import_other_attachment?(webhook)
    webhook['attachments'].present? && webhook['attachments'].count > 1
  end

  def self.is_from_me?(webhook)
    webhook.dig('sender', 'type') == 'user' if webhook.dig('sender', 'id').present?
  end
end
