class Apps::EvolutionApi::Instance::UpdateSettings
  def self.call(evolution_api)
    Faraday.post(
      "#{evolution_api.endpoint_url}/settings/set/#{evolution_api.instance}",
      {
        "rejectCall": false,
        # "msgCall": "",
        "groupsIgnore": false,
        "alwaysOnline": false,
        "readMessages": false,
        "readStatus": false
      }.to_json,
      evolution_api.request_instance_headers
    )
  end
end
