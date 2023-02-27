class Accounts::Apps::WppConnects::Connection::Status

  def self.call(wpp_connect_id)
    whatsapp = Apps::WppConnect.find(wpp_connect_id)

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