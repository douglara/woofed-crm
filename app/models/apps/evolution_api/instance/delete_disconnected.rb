class Apps::EvolutionApi::Instance::DeleteDisconnected
  def initialize(evolution_api)
    @evolution_api = evolution_api
  end

  def call
    check_if_instance_is_disconnected_or_deleted
    if @instance_disconnected
      delete_instance_request
      delete_result = delete_instance_request
      @evolution_api.update(connection_status: 'disconnected', qrcode: '', phone: '') if delete_result.key?(:ok)
    else
      { error: 'Cannot delete, instance is already connected on evolution API server' }
    end
  end

  def delete_instance_request
    return { ok: 'Instance is already deleted ' } unless @instance_founded

    request = Faraday.delete(
      "#{@evolution_api.endpoint_url}/instance/delete/#{@evolution_api.instance}",
      {},
      @evolution_api.request_instance_headers
    )
    { ok: JSON.parse(request.body) }
  end

  def check_if_instance_is_disconnected_or_deleted
    request = Faraday.get(
      "#{@evolution_api.endpoint_url}/instance/connectionState/#{@evolution_api.instance}",
      {},
      @evolution_api.request_instance_headers
    )
    @instance_founded = request.status == 200
    request_body = JSON.parse(request.body)
    @instance_disconnected = request_body.dig('instance', 'state') == 'close' || request.status != 200
  end
end
