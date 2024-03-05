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
      if attachments?(webhook)
        message = import_message_with_attachments(chatwoot, contact, webhook)
      else
        message = import_message(chatwoot, contact, webhook)
      end
    end
    message
  end

  def self.import_message_with_attachments(chatwoot, contact, webhook)
    webhook['attachments'].reverse.map.with_index do |attachment, index|
      import_message(
        chatwoot, contact, webhook,
        { attachment: attachment, order: index, last_element: last_element?(index, webhook)}
        )
    end
  end

  def self.last_element?(index, webhook)
    index == webhook['attachments'].count - 1
  end

  def self.import_message(chatwoot, contact, webhook, attachment_params = {})
    message = contact.events.new(
      account: chatwoot.account,
      kind: 'chatwoot_message',
      from_me: is_from_me?(webhook),
      contact: contact,
      done: true,
      done_at: build_done_at(webhook, attachment_params[:order]),
      app: chatwoot
    )
    message.additional_attributes.merge!({ 'chatwoot_id' => webhook['conversation']['messages'].first['id'] })

    if attachment_params.present?
      create_attachment(message, attachment_params[:attachment])
      message.content = webhook['content'] if attachment_params[:last_element] == true
    else
      message.content = webhook['content']
    end

    message.save
    message
  end

  def self.create_attachment(event, attachment_params)
    begin
      downloaded_file = URI.open(attachment_params['data_url'])
      attachment = event.build_attachment(
        file_type: attachment_params['file_type']
      )
      attachment.file.attach(io: downloaded_file,
                             filename: File.basename(attachment_params['data_url']))
    rescue OpenURI::HTTPError
      event.status = 'failed'
    end
  end

  def self.build_done_at(webhook, order = nil)
    if order.present?
      created_at = webhook['created_at'].dup
      created_at.to_time + miliseconds(order)
    else
      webhook['created_at']
    end
  end

  def self.miliseconds(miliseconds)
    miliseconds/1000.0
  end

  def self.attachments?(webhook)
    webhook['attachments'].present?
  end

  def self.is_from_me?(webhook)
    webhook.dig('sender', 'type') == 'user' if webhook.dig('sender', 'id').present?
  end
end
