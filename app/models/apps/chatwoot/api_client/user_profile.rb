# frozen_string_literal: true

module Apps::Chatwoot::ApiClient::UserProfile
  def user_profile
    response = get_request('/api/v1/profile')

    return { error: 'Failed to fetch user profile', request: response[:request] } if response[:request].status != 200

    response
  end
end
