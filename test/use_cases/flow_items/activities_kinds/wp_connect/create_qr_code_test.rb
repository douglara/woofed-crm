require "test_helper"
include WithVCR

class FlowItems::ActivitiesKinds::WpConnect::CreateQrCodeTest < ActiveSupport::TestCase
  test "should return error" do
    result = FlowItems::ActivitiesKinds::WpConnect::CreateQrCode.call({
      'secretkey': '',
      'endpoint_url': ''
    })
    assert result.key?(:error), true
  end

  test "should return true" do
    with_expiring_vcr_cassette do
      result = FlowItems::ActivitiesKinds::WpConnect::CreateQrCode.call({
        'secretkey': 'THISISMYSECURETOKEN',
        'endpoint_url': 'https://wppconnect-server-open-crm.herokuapp.com'
      })
      assert result.key?(:ok), true
    end
  end
end
