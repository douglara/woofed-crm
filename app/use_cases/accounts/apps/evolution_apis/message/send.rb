class Accounts::Apps::EvolutionApis::Message::Send
  def initialize(evolution_api, phone, event)
    @evolution_api = evolution_api
    @phone = phone
    @event = event
  end

  def call
    if @event.attachment.present?
      send_message_with_attachment
    else
      send_message_without_attachment
    end
  end

  def send_message_with_attachment
    if @event.attachment.audio?
      send_message_audio
    else
      send_message_file
    end
  end

  def send_message_audio
    request = Faraday.post(
      "#{@evolution_api.endpoint_url}/message/sendWhatsAppAudio/#{@evolution_api.instance}",
      build_message_audio_body.to_json,
      @evolution_api.request_instance_headers
    )
    if request.status == 201
      { ok: JSON.parse(request.body) }

    else
      { error: JSON.parse(request.body) }
    end
  end

  def send_message_file
    request = Faraday.post(
      "#{@evolution_api.endpoint_url}/message/sendMedia/#{@evolution_api.instance}",
      build_message_file_body.to_json,
      @evolution_api.request_instance_headers
    )
    if request.status == 201
      { ok: JSON.parse(request.body) }

    else
      { error: JSON.parse(request.body) }
    end
  end

  def send_message_without_attachment
    request = Faraday.post(
      "#{@evolution_api.endpoint_url}/message/sendText/#{@evolution_api.instance}",
      build_message_text_body.to_json,
      @evolution_api.request_instance_headers
    )

    if request.status == 201
      { ok: JSON.parse(request.body) }

    else
      { error: JSON.parse(request.body) }
    end
  end

  def build_message_file_body
    file_url = Rails.application.routes.url_helpers.rails_blob_url(@event.attachment.file)
    file_media_type = if @event.attachment.image? || @event.attachment.video?
                        @event.attachment.file_type
                      else
                        'document'
                      end
    {
      "number": @phone.sub(/^\+/, ''),
      "options": {
        "delay": 1200,
        "presence": 'composing',
        "linkPreview": false
      },
      "mediaMessage": {
        "mediatype": file_media_type,
        "caption": @event.generate_content_hash('content', event.content)['content'],
        "media": file_url
      }
    }
  end

  def build_message_audio_body
    file_url = Rails.application.routes.url_helpers.rails_blob_url(@event.attachment.file)
    {
      "number": @phone.sub(/^\+/, ''),
      "options": {
        "delay": 1200,
        "presence": 'recording',
        "linkPreview": false
      },
      "audioMessage": {
        "audio": file_url
      }
    }
  end

  def build_message_text_body
    {
      "number": @phone.sub(/^\+/, ''),
      "options": {
        "delay": 1200,
        "presence": 'composing',
        "linkPreview": false
      },
      "textMessage": {
        "text": @event.content
      }
    }
  end
end
