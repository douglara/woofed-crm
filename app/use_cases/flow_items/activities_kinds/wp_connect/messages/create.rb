class FlowItems::ActivitiesKinds::WpConnect::Messages::Create

  def self.call(message_params)
    message = FlowItem.new(message_params)
    message.from_me = true
    message = send_message(message)

    if save(message) && message.done == true
      return { ok: message }
    else
      return { error: message }
    end
  end
  
  def self.save(message)
    ActiveRecord::Base.transaction do
      message.kind = FlowItems::ActivitiesKinds::WpConnect.find(message.kind_id)
      message.save!
    end
  end

  def self.send_message(message)
    new_message = message
    result = make_request(new_message)

    if result.key?(:ok)
      new_message.done = true
      new_message.scheduled_at = Time.at(result[:ok]['t'])
      new_message.source_id = result[:ok]['id']
      return new_message
    else
      new_message.done = false
      return new_message
    end
  end


  def self.make_request(message)
    wp_connect = FlowItems::ActivitiesKinds::WpConnect.find(message.kind_id)
    contact = Contact.find(message.contact_id)
    response = Faraday.post(
      "#{wp_connect.endpoint_url}/api/#{wp_connect.session}/send-message",
      {
        "phone": "#{contact.phone}",
        "message": "#{message.content}",
        "isGroup": false
      }.to_json,
      {'Authorization': "Bearer #{wp_connect.token}", 'Content-Type': 'application/json'}
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