require "test_helper"
include WithVCR

class FlowItems::ActivitiesKinds::WpConnect::Connection::StatusTest < ActiveSupport::TestCase
  test "should return error" do
    with_expiring_vcr_cassette() do
      result = FlowItems::ActivitiesKinds::WpConnect::Connection::Status.call({
        'secretkey': 'THISISMYSECURETOKEN',
        'endpoint_url': 'https://wppconnect-server-open-crm.herokuapp.com',
        'session': 'session_1632446075',
        'token': '$2b$10$XbwuBfjzn5LexQ7IY9AXn.glF0vr9VkZ9gKHJunRvIHfRTNbambIW'
      })
      assert result.key?(:error), true
    end
  end

  test "should return true" do
    stub_request(:get, "https://wppconnect-server-open-crm.herokuapp.com/api/session_1632446075/check-connection-session").to_return(body: '{"message": "Connected"}')

    result = FlowItems::ActivitiesKinds::WpConnect::Connection::Status.call({
      'secretkey': 'THISISMYSECURETOKEN',
      'endpoint_url': 'https://wppconnect-server-open-crm.herokuapp.com',
      'session': 'session_1632446075',
      'token': '$2b$10$XbwuBfjzn5LexQ7IY9AXn.glF0vr9VkZ9gKHJunRvIHfRTNbambIW'
    })
    assert result.key?(:ok), true
  end
end
