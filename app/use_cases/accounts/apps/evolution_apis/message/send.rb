class Accounts::Apps::EvolutionApis::Message::Send
  def self.call(evolution_api, phone, event)
    if event.attachment.present?
      send_message_with_attachment(evolution_api, phone, event)
    else
      send_message_without_attachment(evolution_api, phone, event)
    end
  end

  def self.send_message_with_attachment(evolution_api, phone, event)
    request = Faraday.post(
      "#{evolution_api.endpoint_url}/message/sendMedia/#{evolution_api.instance}",
      build_message_attachment_body(phone, event).to_json,
      evolution_api.request_instance_headers
    )

    if request.status == 201
      { ok: JSON.parse(request.body) }

    else
      { error: JSON.parse(request.body) }
    end
  end

  def self.send_message_without_attachment(evolution_api, phone, event)
    request = Faraday.post(
      "#{evolution_api.endpoint_url}/message/sendText/#{evolution_api.instance}",
      build_message_text_body(phone, event.content).to_json,
      evolution_api.request_instance_headers
    )
    if request.status == 201
      { ok: JSON.parse(request.body) }

    else
      { error: JSON.parse(request.body) }
    end
  end

  def self.build_message_attachment_body(phone, event)
    file_url = Rails.application.routes.url_helpers.rails_blob_url(event.attachment.file)
    {
      "number": phone.sub(/^\+/, ''),
      "options": {
        "delay": 1200,
        "presence": 'composing',
        "linkPreview": false
      },
      "mediaMessage": {
        "mediatype": event.attachment.file_type,
        "caption": event.content,
        "media": file_url
      }
    }
  end

  def self.build_message_audio_body(phone, event)
    file_url = Rails.application.routes.url_helpers.rails_blob_url(event.attachment.file)
    {
      "number": phone.sub(/^\+/, ''),
      "options": {
        "delay": 1200,
        "presence": 'recording',
        "linkPreview": false
      },
      "mediaMessage": {
        "audio": file_url
      }
    }
  end

  def self.build_message_text_body(phone, event)
    {
      "number": phone.sub(/^\+/, ''),
      "options": {
        "delay": 1200,
        "presence": 'composing',
        "linkPreview": false
      },
      "textMessage": {
        "text": event
      }
    }
  end
end
