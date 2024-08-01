class Accounts::Apps::EvolutionApis::Instance::Delete
  def self.call(evolution_api)
    if inactive?(evolution_api)
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
    if request.status == 200
      evolution_api.update(connection_status: 'disconnected', qrcode: '', phone: '')
      { ok: JSON.parse(request.body) }
    else
      { error: JSON.parse(request.body) }
    end
  end

  def self.inactive?(evolution_api)
    request = Faraday.get(
      "#{evolution_api.endpoint_url}/instance/connectionState/#{evolution_api.instance}",
      {},
      evolution_api.request_instance_headers
    )

    request.status != 200
  end
end
