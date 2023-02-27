class Accounts::Apps::WppConnects::Events::DeliveryMessage

  def self.call(event)
    result_event = send_message(event)

    if result_event.save && result_event.done == true
      return { ok: result_event }
    else
      return { error: result_event }
    end
  end

  def self.send_message(message)
    new_message = message
    result = make_request(new_message)

    if result.key?(:ok)
      new_message.done = true
      new_message.due = Time.at(result[:ok]['t'])
      new_message.custom_attributes['source_id'] = result[:ok]['id']
      return new_message
    else
      new_message.done = false
      return new_message
    end
  end


  def self.make_request(event)
    wpp_connect = event.app
    contact = event.contact
    response = Faraday.post(
      "#{wpp_connect.endpoint_url}/api/#{wpp_connect.session}/send-message",
      {
        "phone": "#{event.custom_attributes['wpp_connect_message_phone']}",
        "message": "#{event.content.to_plain_text}",
        "isGroup": false
      }.to_json,
      {'Authorization': "Bearer #{wpp_connect.token}", 'Content-Type': 'application/json'}
    )
    delivery_message?(response)
  end

  def self.delivery_message?(response)
    body = JSON.parse(response.body)

    if response.status == 201 && body['response'][0]['id'].present?
      return { ok: body['response'][0] }
    else
      return { error: response }
    end

    rescue 
      { error: false }
  end
end