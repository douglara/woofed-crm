class Accounts::Apps::EvolutionApis::Instance::Logout

  def self.call(evolution_api)
    request = Faraday.delete(
      "#{evolution_api.endpoint_url}/instance/logout/#{evolution_api.instance}",
      {},
      evolution_api.request_instance_headers
    )
    if request.status == 200
      return { ok: JSON.parse(request.body) }
    else
      return { error: JSON.parse(request.body) }
    end
  end
end
