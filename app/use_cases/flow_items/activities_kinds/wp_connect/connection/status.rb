class FlowItems::ActivitiesKinds::WpConnect::Connection::Status

  def self.call(whatsapp_params)
    whatsapp = FlowItems::ActivitiesKinds::WpConnect.new(whatsapp_params)

    response = Faraday.get(
      "#{whatsapp.endpoint_url}/api/#{whatsapp.session}/status-session",
      {},
      {'Authorization': "Bearer #{whatsapp.token}", 'Content-Type': 'application/json'}
    )

    body = JSON.parse(response.body)

    if connected?(body)
      return {ok: body}
    else
      return {error: body}
    end
  end

  def self.connected?(response_body)
    response_body['status'] == 'CONNECTED'
  rescue
    false
  end
end