class Accounts::Apps::EvolutionApis::Instance::Delete

  def self.call(evolution_api)
    request = Faraday.delete(
      "#{evolution_api.endpoint_url}/instance/delete/#{evolution_api.instance}",
      {},
      evolution_api.request_instance_headers
    )
    if request.status == 200
      evolution_api.update(connection_status: 'disconnected', qrcode: '')
      return { ok: JSON.parse(request.body) }
    else
      return { error: JSON.parse(request.body) }
    end
  end
end
