require "test_helper"
include WithVCR

class Contacts::FlowItems::ActivitiesKinds::WpConnections::Messages::SyncTest < ActiveSupport::TestCase
  test "should return true" do
    with_expiring_vcr_cassette do
      wp_connect = FlowItems::ActivitiesKinds::WpConnect.create(
        session: ENV['WP_CONNECT_SESSION'],
        token: ENV['WP_CONNECT_TOKEN'],
        endpoint_url: ENV['WP_CONNECT_ENDPOINT'],
        enabled: true,
        secretkey: ENV['WP_CONNECT_SECRET_KEY']
      )

      contact = Contact.create(
        full_name: 'Douglas',
        phone: '5541996910256'
      )

      result = Contacts::FlowItems::ActivitiesKinds::WpConnections::Messages::Sync.call(contact)
      assert result.key?(:ok), true
      assert (contact.flow_items.count > 1), true
    end
  end
end
