class Accounts::Apps::Chatwoots::Webhooks::ImportMessage

  def self.call(chatwoot, contact, webhook)
    message = get_or_import_message(chatwoot, contact, webhook)
    return { ok: contact }
  end

  def self.get_or_import_message(chatwoot, contact, webhook)
    message = contact.events.where(
      "? <@ additional_attributes", { chatwoot_id: webhook['id'] }.to_json
    ).first

    if message.present?
      return message
    else
      message = import_message(chatwoot, contact, webhook)
      return contact
    end
  end

  def self.import_message(chatwoot, contact, webhook)
    contact.events.create(
      account: chatwoot.account,
      kind: 'chatwoot_message',
      from_me: is_from_me?(webhook),
      contact: contact,
      content: webhook['content'],
      app: chatwoot
    )
  end

  def self.is_from_me?(webhook)
    if webhook.dig('sender', 'id').present?
      if webhook.dig('sender', 'id') == 'user'
        return true
      else
        return false
      end
    else
      return nil
    end
  end
end