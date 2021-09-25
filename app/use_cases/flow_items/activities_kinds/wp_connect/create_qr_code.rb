class FlowItems::ActivitiesKinds::WpConnect::CreateQrCode

  def self.call(whatsapp_params)
    whatsapp = FlowItems::ActivitiesKinds::WpConnect.new(whatsapp_params)
    whatsapp.session = "session_#{DateTime.now.to_i}"
    whatsapp.token = generate_token(whatsapp)[:ok]
    qr_code = create_qr_code(whatsapp)

    if qr_code.key?(:error)
      return { error: { wp_connect: whatsapp, qr_code: qr_code } }
    else
      return { ok: { wp_connect: whatsapp, qr_code: qr_code[:ok] } }
    end
  rescue Exception => ex
    { error: ex }
  end

  def self.generate_token(whatsapp)
    response = Faraday.post(
      "#{whatsapp.endpoint_url}/api/#{whatsapp.session}/#{whatsapp.secretkey}/generate-token"
    )
    body = JSON.parse(response.body)

    if valid_session_token?(response)
      return { ok: body['token'] }
    else
      return { error: response }
    end
  end

  def self.valid_session_token?(response)
    body = JSON.parse(response.body)
    response.status == 201 && body['token'].present?
  end
  
  def self.create_qr_code(whatsapp)
    response = Faraday.post(
      "#{whatsapp.endpoint_url}/api/#{whatsapp.session}/start-session",
      {
        "webhook": nil,
        "waitQrCode": true
      }.to_json,
      {'Authorization': "Bearer #{whatsapp.token}", 'Content-Type': 'application/json'}
    )

    get_qr_code(response)
  end

  def self.get_qr_code(response)
    body = JSON.parse(response.body)

    if body.key?('qrcode')
      return { ok: body['qrcode'] }
    else
      return { error: body }
    end

    rescue 
      return { error: response}
  end
end