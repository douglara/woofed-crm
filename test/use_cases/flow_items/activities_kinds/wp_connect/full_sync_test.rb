require "test_helper"
include WithVCR

class FlowItems::ActivitiesKinds::WpConnect::FullSyncTest < ActiveSupport::TestCase
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
        phone: '41996910256'
      )

      result = FlowItems::ActivitiesKinds::WpConnect::FullSync.new(wp_connect).call
      assert result.key?(:ok), true
    end
  end
end
