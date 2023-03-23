class Accounts::Apps::WppConnects::Connection::RefreshStatus

  def self.call(wpp_connect_id)
    whatsapp = Apps::WppConnect.find(wpp_connect_id)

    response = Faraday.get(
      "#{whatsapp.endpoint_url}/api/#{whatsapp.session}/status-session",
      {},
      {'Authorization': "Bearer #{whatsapp.token}", 'Content-Type': 'application/json'}
    )

    body = JSON.parse(response.body)

    if connected?(body)
      whatsapp.update(status: 'active', active: true)
      return {ok: body}
    else
      whatsapp.update(status: 'inactive', active: false)
      return {error: body}
    end
  end

  def self.connected?(response_body)
    response_body['status'] == 'CONNECTED'
  rescue
    false
  end
end