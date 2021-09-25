require "test_helper"

class FlowItems::ActivitiesKinds::WpConnect::Messages::CreateTest < ActiveSupport::TestCase
  test "should delivery" do
    stub_request(:post, "https://wppconnect-server-open-crm.herokuapp.com/api/session_1632535308/send-message").to_return(
      body: '{"response": [{"id": "123", "id": "true_5551@c.us_3EB0F86C0F139CE13589", "t": 1632595138}]}', status: 201)

    wp_connect = FlowItems::ActivitiesKinds::WpConnect.create(
      session: 'session_1632535308',
      token: '$2b$10$OfB88q2GUqt36UmbohBAx.QO51NtWKB58W.kAs5uX2Pk6iHGtEKAW',
      endpoint_url: 'https://wppconnect-server-open-crm.herokuapp.com',
      enabled: true,
      secretkey: 'THISISMYSECURETOKEN'
    )

    contact = Contact.create(
      full_name: 'Douglas',
      phone: '41996910256'
    )

    result = FlowItems::ActivitiesKinds::WpConnect::Messages::Create.call({
      'content': 'Test',
      'kind_id': wp_connect.id,
      'contact_id': contact.id
    })
    assert result.key?(:ok), true
  end
end
