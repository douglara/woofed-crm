class ActivityKinds::Whatsapp::Settings::Activate

  def initialize(activity_kind_whatsapp, params)
    @activity_kind_whatsapp = activity_kind_whatsapp
    @params = params
  end

  def perform
    @activity_kind_whatsapp.update(@params)
    result = check_and_start_session
    if result
      @activity_kind_whatsapp['settings']['enabled'] = true
      @activity_kind_whatsapp.save
      return true
    else
      @activity_kind_whatsapp['settings']['enabled'] = false
      @activity_kind_whatsapp.save
      return false
    end
  end

  def check_and_start_session
    valid_credentials? && session_active?
  end

  def valid_credentials?
    response = Faraday.get(
      "#{@activity_kind_whatsapp['settings']['endpoint_url']}/api/#{@activity_kind_whatsapp['settings']['session']}/status-session",
      {},
      {'Authorization': "Bearer #{@activity_kind_whatsapp['settings']['token']}"}
    )
    response.status == 200
  end

  def session_active?
    response = Faraday.get(
      "#{@activity_kind_whatsapp['settings']['endpoint_url']}/api/#{@activity_kind_whatsapp['settings']['session']}/status-session",
      {},
      {'Authorization': "Bearer #{@activity_kind_whatsapp['settings']['token']}"}
    )
    body = JSON.parse(response.body)
    body['status'] == 'CONNECTED'
  end
end