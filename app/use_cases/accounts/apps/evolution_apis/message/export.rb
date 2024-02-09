class Accounts::Apps::EvolutionApis::Message::Export
  def self.call(evolution_api, phone, content)
    request = Faraday.post(
      "#{evolution_api.endpoint_url}/message/sendText/#{evolution_api.instance}",
      build_body(phone, content).to_json,
      evolution_api.request_instance_headers
    )
    if request.status == 201
      { ok: JSON.parse(request.body) }

    else
      { error: JSON.parse(request.body) }
    end
  end
  def self.build_body(phone, content)
    {
      "number": phone.sub(/^\+/, ""),
      "options": {
        "delay": 1200,
        "presence": "composing",
        "linkPreview": false
      },
      "textMessage": {
        "text": content
      }
    }
  end
end
