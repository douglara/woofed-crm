require 'html2text'

class Activities::Whatsapp::Message::Send
  def initialize(activity)
    @activity = activity
    @activity_kind_whatsapp ||= ActivityKind.find_by_key('whatsapp')
  end

  def perform
    make_request()
  end

  def make_request
    response = Faraday.post(
      "#{@activity_kind_whatsapp['settings']['endpoint_url']}/api/#{@activity_kind_whatsapp['settings']['session']}/send-message",
      {
        "phone": "55#{@activity.flow_item.contact.phone}",
        "message": "#{sanitize_text(@activity.content)}",
        "isGroup": false
      }.to_json,
      {'Authorization': "Bearer #{@activity_kind_whatsapp['settings']['token']}", 'Content-Type': 'application/json'}
    )
    body = JSON.parse(response.body)
    delivery_message?(response)
  end

  def delivery_message?(response)
    body = JSON.parse(response.body)
    response.status == 201 && (body['response'][0]['id'].present? rescue false)
  end

  def sanitize_text(text)
    Html2Text.convert(text)
  end
end