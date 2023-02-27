

class Accounts::Apps::WppConnects::CreateQrCode
  
  def self.call(wpp_connect_id)
    wpp_connect = Apps::WppConnect.find(wpp_connect_id)
    wpp_connect.session = "session_#{DateTime.now.to_i}"
    wpp_connect.token = generate_token(wpp_connect)[:ok]
    qr_code = create_qr_code(wpp_connect)

    if qr_code.key?(:error)
      return { error: { wp_connect: wpp_connect, qr_code: qr_code } }
    else
      wpp_connect.save
      return { ok: { wp_connect: wpp_connect, qr_code: qr_code[:ok] } }
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
        "webhook": "#{Rails.application.routes.url_helpers.api_v1_account_apps_wpp_connect_webhook_url(whatsapp.account, whatsapp.id)}",
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