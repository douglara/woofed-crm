class Apps::EvolutionApi::Instance::Create

  def self.call(evolution_api)
    evolution_api.update(connection_status: 'connecting')
    request = Faraday.post(
      "#{evolution_api.endpoint_url}/instance/create",
      build_body(evolution_api).to_json,
      {'apiKey': "#{ENV['EVOLUTION_API_ENDPOINT_TOKEN']}", 'Content-Type': 'application/json'}
    )
    if request.status == 201
      # set_settings(evolution_api)
      return { ok: JSON.parse(request.body) }
    else
      evolution_api.update(connection_status: 'disconnected')
      return { error: JSON.parse(request.body) }
    end
  end

  def self.set_settings(evolution_api)
    Faraday.post(
      "#{evolution_api.endpoint_url}/settings/set/#{evolution_api.instance}",
      {
      "rejectCall": false,
      #"msgCall": "",
      "groupsIgnore": false,
      "alwaysOnline": false,
      "readMessages": false,
      "readStatus": false,
      }.to_json,
      evolution_api.request_instance_headers
    )
  end

  def self.build_body(evolution_api)
    {
      "instanceName": evolution_api.instance,
      "token": evolution_api.token,
      "qrcode": true,
      "rejectCall": false,
      #"msgCall": "",
      "groupsIgnore": false,
      "alwaysOnline": false,
      "readMessages": false,
      "readStatus": false,
      #"syncFullHistory": false,
      "webhook": {
        "url": evolution_api.woofedcrm_webhooks_url,
        "byEvents": true,
        "base64": true,
        "headers": {
          "Content-Type": "application/json"
        },
        "events": [
          "APPLICATION_STARTUP",
          "QRCODE_UPDATED",
          "MESSAGES_SET",
          "MESSAGES_UPSERT",
          "MESSAGES_UPDATE",
          "MESSAGES_DELETE",
          "SEND_MESSAGE",
          "CONTACTS_SET",
          "CONTACTS_UPSERT",
          "CONTACTS_UPDATE",
          "PRESENCE_UPDATE",
          "CHATS_SET",
          "CHATS_UPSERT",
          "CHATS_UPDATE",
          "CHATS_DELETE",
          "GROUPS_UPSERT",
          "GROUP_UPDATE",
          "GROUP_PARTICIPANTS_UPDATE",
          "CONNECTION_UPDATE",
          "LABELS_EDIT",
          "LABELS_ASSOCIATION",
          "CALL"
        ]
      },
    }
  end
end
