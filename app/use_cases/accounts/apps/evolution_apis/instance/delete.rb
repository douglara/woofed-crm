class Accounts::Apps::EvolutionApis::Instance::Delete
  def self.call(evolution_api, delete_instance = false)
    if inactive?(evolution_api) || delete_instance
      send_delete_instance_request(evolution_api)
    else
      { error: 'Cannot delete, instance is already active on evolution API server' }
    end
  end

  def self.send_delete_instance_request(evolution_api)
    request = Faraday.delete(
      "#{evolution_api.endpoint_url}/instance/delete/#{evolution_api.instance}",
      {},
      evolution_api.request_instance_headers
    )
    evolution_api.update(connection_status: 'disconnected', qrcode: '', phone: '')
    { ok: JSON.parse(request.body) }
  end

  def self.inactive?(evolution_api)
    request = Faraday.get(
      "#{evolution_api.endpoint_url}/instance/connectionState/#{evolution_api.instance}",
      {},
      evolution_api.request_instance_headers
    )
    request_body = JSON.parse(request.body)
    return true if request_body.dig('instance', 'state') == 'close' || request.status != 200

    false
  end
end
