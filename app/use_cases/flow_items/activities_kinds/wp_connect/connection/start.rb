class FlowItems::ActivitiesKinds::WpConnect::Connection::Start

  def self.call(wp_connect)
    webhook_url = "#{ENV['HOST_URL']}/api/v1/flow_items/wp_connects/#{wp_connect.id}/webhook?token=#{wp_connect.token}"
    response = Faraday.post(
      "#{wp_connect.endpoint_url}/api/#{wp_connect.session}/start-session",
      {
        "webhook": webhook_url,
        "waitQrCode": true
      }.to_json,
      {'Authorization': "Bearer #{wp_connect.token}", 'Content-Type': 'application/json'}
    )

    body = JSON.parse(response.body)
    return { ok: body }
  end
end