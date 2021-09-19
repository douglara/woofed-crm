class Activities::Whatsapp::Connection::New
  def initialize()
    @activity_kind_whatsapp = ActivityKind.find_by_key('whatsapp')
  end

  def connected?
    connection_status = connection_status()
    body = JSON.parse(connection_status.body)
    return connection_status.status == 200 && body['message'] == 'Connected'
  end

  def connection_status
    response = Faraday.get(
      "#{@activity_kind_whatsapp['settings']['endpoint_url']}/api/#{@activity_kind_whatsapp['settings']['session']}/check-connection-session",
      {},
      {'Authorization': "Bearer #{@activity_kind_whatsapp['settings']['token']}", 'Content-Type': 'application/json'}
    )
  end

  def generate_qr_code
    token = generate_token()
    save_token(token[:ok])
    qr_code = get_qr_code()
    return { ok: qr_code['qrcode'] }
    rescue
      return { error: false}
  end

  def save_token(token)
    @activity_kind_whatsapp['settings']['token'] = token['token']
    @activity_kind_whatsapp['settings']['session'] = token['session']
    @activity_kind_whatsapp.save
  end

  def generate_token
    session_name = "session_#{DateTime.now.to_i}"
    response = Faraday.post(
      "#{@activity_kind_whatsapp['settings']['endpoint_url']}/api/#{session_name}/#{@activity_kind_whatsapp['settings']['secretkey']}/generate-token"
    )
    body = JSON.parse(response.body)

    if valid_session_token?(response)
      return { ok: body }
    else
      return { error: response }
    end
  end

  def get_qr_code
    response = Faraday.post(
      "#{@activity_kind_whatsapp['settings']['endpoint_url']}/api/#{@activity_kind_whatsapp['settings']['session']}/start-session",
      {
        "webhook": nil,
        "waitQrCode": true
      }.to_json,
      {'Authorization': "Bearer #{@activity_kind_whatsapp['settings']['token']}", 'Content-Type': 'application/json'}
    )
    JSON.parse(response.body)
  end

  def valid_session_token?(response)
    body = JSON.parse(response.body)
    response.status == 201 && body['token'].present?
  end
end