require "test_helper"
include WithVCR

class FlowItems::ActivitiesKinds::WpConnect::CreateTest < ActiveSupport::TestCase
  test "should return true" do
    result = FlowItems::ActivitiesKinds::WpConnect::Create.call({
      'secretkey': 'THISISMYSECURETOKEN',
      'endpoint_url': 'https://wppconnect-server-open-crm.herokuapp.com',
      'session': 'session_1632446075',
      'token': '$2b$10$XbwuBfjzn5LexQ7IY9AXn.glF0vr9VkZ9gKHJunRvIHfRTNbambIW',
    })
    assert result.key?(:ok), true
  end
end
