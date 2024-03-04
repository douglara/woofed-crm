class Accounts::Apps::Chatwoots::Webhooks::ImportMessage
  require 'open-uri'

  def self.call(chatwoot, contact, webhook)
    message = get_or_import_message(chatwoot, contact, webhook)
    { ok: message }
  end

  def self.get_or_import_message(chatwoot, contact, webhook)
    message = contact.events.where(
      '? <@ additional_attributes', { chatwoot_id: webhook['conversation']['messages'].first['id'] }.to_json
    ).first
    if message.nil?
      if has_multiple_attachments?(webhook)
        Accounts::Apps::Chatwoots::Webhooks::ImportAttachmentsSkipFirst.call(chatwoot, contact, webhook)
        message = import_message(chatwoot, contact, webhook)
      else
        message = import_message(chatwoot, contact, webhook)
      end
    end
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
      done_at: build_done_at(webhook),
      app: chatwoot
    )

    message.additional_attributes.merge!({ 'chatwoot_id' => webhook['conversation']['messages'].first['id'] })
    if webhook['attachments'].present?
      Accounts::Apps::Chatwoots::Webhooks::ImportAttachmentsSkipFirst.create_attachment(message,
                                                                               webhook['attachments'].first)
    end

    message.save
    message
  end

  def self.build_done_at(webhook)
    if webhook['attachments'].present?
      created_at = webhook['created_at'].dup
      created_at.to_time + miliseconds(1)
    else
      webhook['created_at']
    end
  end

  def self.miliseconds(miliseconds)
    miliseconds/1000.0
  end

  def self.has_multiple_attachments?(webhook)
    webhook['attachments'].present? && webhook['attachments'].count > 1
  end

  def self.is_from_me?(webhook)
    webhook.dig('sender', 'type') == 'user' if webhook.dig('sender', 'id').present?
  end
end
