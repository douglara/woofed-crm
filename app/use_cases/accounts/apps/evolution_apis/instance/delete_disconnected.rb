class Accounts::Apps::EvolutionApis::Instance::DeleteDisconnected
  def initialize(evolution_api)
    @evolution_api = evolution_api
  end

  def call
    if disconnected_or_deleted?
      send_delete_instance_request
      @evolution_api.update(connection_status: 'disconnected', qrcode: '', phone: '')
    else
      { error: 'Cannot delete, instance is already active on evolution API server' }
    end
  end

  def send_delete_instance_request
    return unless @evolution_api_instance_found

    request = Faraday.delete(
      "#{@evolution_api.endpoint_url}/instance/delete/#{@evolution_api.instance}",
      {},
      @evolution_api.request_instance_headers
    )
    { ok: JSON.parse(request.body) }
  end

  def disconnected_or_deleted?
    request = Faraday.get(
      "#{@evolution_api.endpoint_url}/instance/connectionState/#{@evolution_api.instance}",
      {},
      @evolution_api.request_instance_headers
    )
    @evolution_api_instance_found = request.status == 200
    request_body = JSON.parse(request.body)
    return true if request_body.dig('instance', 'state') == 'close' || request.status != 200

    false
  end
end
