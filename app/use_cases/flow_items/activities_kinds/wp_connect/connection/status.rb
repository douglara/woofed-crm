class FlowItems::ActivitiesKinds::WpConnect::Connection::Status

  def self.call(whatsapp_params)
    whatsapp = FlowItems::ActivitiesKinds::WpConnect.new(whatsapp_params)

    response = Faraday.get(
      "#{whatsapp.endpoint_url}/api/#{whatsapp.session}/check-connection-session",
      {},
      {'Authorization': "Bearer #{whatsapp.token}", 'Content-Type': 'application/json'}
    )

    if connected?(response)
      return {ok: response}
    else
      return {error: response}
    end
  end

  def self.connected?(response)
    body = JSON.parse(response.body)
    body['message'] == 'Connected'
  rescue
    false
  end
end