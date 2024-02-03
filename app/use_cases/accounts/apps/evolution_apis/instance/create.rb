class Accounts::Apps::EvolutionApis::Instance::Create

  def self.call(evolution_api)
    evolution_api.update(connection_status: 'connecting')
    request = Faraday.post(
      "#{evolution_api.endpoint_url}/instance/create",
      build_body(evolution_api).to_json,
      {'apiKey': "#{ENV['EVOLUTION_API_ENDPOINT_TOKEN']}", 'Content-Type': 'application/json'}
    )
    if request.status == 201
      return { ok: JSON.parse(request.body) }
    else
      evolution_api.update(connection_status: 'disconnected')
      return { error: JSON.parse(request.body) }
    end
  end

  def self.build_body(evolution_api)
    {
      "instanceName": evolution_api.instance,
      "token": evolution_api.token,
      "qrcode": true,
      "webhook": evolution_api.woofedcrm_webhooks_url,
      "events": [
        "QRCODE_UPDATED",
        "MESSAGES_DELETE",
        "SEND_MESSAGE",
        "CONNECTION_UPDATE",
        "MESSAGES_UPSERT",
      ]
    }
  end

end
