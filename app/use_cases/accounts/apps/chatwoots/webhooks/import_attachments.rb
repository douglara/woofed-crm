class Accounts::Apps::Chatwoots::Webhooks::ImportAttachments
  require 'open-uri'

  def self.call(chatwoot, contact, webhook)
    attachments = get_or_import_attachments(chatwoot, contact, webhook)
    { ok: attachments }
  end

  def self.get_or_import_attachments(chatwoot, contact, webhook)
    return 'Attachments can not be blank' if webhook['attachments'].blank?

    webhook['attachments'].drop(1).map do |attachment|
      attachment = create_event(chatwoot, contact, webhook, attachment)
      attachment
    end
  end

  def self.create_event(chatwoot, contact, webhook, attachment_params)
    event = contact.events.new(
      account: chatwoot.account,
      kind: 'chatwoot_message',
      from_me: Accounts::Apps::Chatwoots::Webhooks::ImportMessage.is_from_me?(webhook),
      contact: contact,
      done: true,
      done_at: webhook['created_at'],
      app: chatwoot
    )
    event.additional_attributes.merge!({ 'chatwoot_id' => attachment_params['message_id'] })
    create_attachment(event, attachment_params)
    event.save
    event
  end

  def self.create_attachment(event, attachment_params)
    downloaded_file = URI.open(attachment_params['data_url'])
    attachment = event.build_attachment(
      file_type: attachment_params['file_type']
    )
    attachment.file.attach(io: downloaded_file,
                           filename: "attachment_#{attachment_params['file_type']}_#{event.additional_attributes['chatwoot_id']}")
  end
end
