class Accounts::Apps::EvolutionApi::Instance::Create

  def self.call(evolution_api)
    request = Faraday.post(
      "#{ENV['EVOLUTION_API_ENDPOINT']}/instance/create",
      build_body(evolution_api).to_json,
      evolution_api.request_headers
    )
    if request.status == 200
      return { ok: JSON.parse(request.body) }
    else
      return { error: JSON.parse(request.body) }
    end

  end
  def self.build_body(evolution_api)
    {
      "instanceName": evolution_api.name,
      "token": evolution_api.token,
      "qrcode": true,
      "number": evolution_api.phone
    }
  end
end
