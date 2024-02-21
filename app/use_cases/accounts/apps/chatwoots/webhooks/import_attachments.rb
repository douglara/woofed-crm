class Accounts::Apps::Chatwoots::Webhooks::ImportAttachments
  def self.call(chatwoot, contact, webhook)
    attachments = get_or_import_attachments(chatwoot, contact, webhook)
    { ok: attachments }
  end

  def self.get_or_import_attachments(chatwoot, contact, webhook)
    return 'Attachments can not be blank' if webhook['attachments'].blank?

    webhook['attachments'].map do |attachment|
      attachment = contact.events.where(
        '? <@ additional_attributes', { chatwoot_id: webhook['id'] }.to_json
      ).first

      attachment = import_attachments(chatwoot, contact, webhook, attachment) if attachment.nil?
      attachment
    end
  end

  def self.import_attachments(chatwoot, contact, webhook, attachment_params)
    event = contact.events.create(
      account: chatwoot.account,
      kind: 'chatwoot_message',
      from_me: Accounts::Apps::Chatwoots::Webhooks::ImportMessage.is_from_me?(webhook),
      contact: contact,
      done: true,
      done_at: webhook['created_at'],
      app: chatwoot
    )

    attachment = event.build_attachment(
      file_type: attachment_params['file_type']
    )
    attachment.file.attach(io: open(attachment_data['data_url']), filename: "attachment_#{attachment_params['file_type']}_#{attachment.id}")
    attachment.save
    attachment
  end

end
