class Accounts::Apps::Chatwoots::Webhooks::ImportMessage
  def self.call(chatwoot, contact, webhook)
    message = get_or_import_message(chatwoot, contact, webhook)
    { ok: message }
  end

  def self.get_or_import_message(chatwoot, contact, webhook)
    return 'Message content can not be blank' if webhook['content'].blank?

    message = contact.events.where(
      '? <@ additional_attributes', { chatwoot_id: webhook['id'] }.to_json
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
    message.save
    message
  end

  def self.is_from_me?(webhook)
    webhook.dig('sender', 'type') == 'user' if webhook.dig('sender', 'id').present?
  end
end
