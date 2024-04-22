class Accounts::Apps::EvolutionApis::Instance::RefreshStatus
  def initialize(evolution_api)
    @evolution_api = evolution_api
  end

  def call
    @evolution_api.update(connection_status: 'disconnected') if inactive?
  end

  def inactive?
    request = Faraday.get(
      "#{@evolution_api.endpoint_url}/instance/connectionState/#{@evolution_api.instance}",
      {},
      @evolution_api.request_instance_headers
    )

    request.status != 200
  end
end
