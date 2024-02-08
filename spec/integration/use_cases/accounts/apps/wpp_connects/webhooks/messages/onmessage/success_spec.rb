require 'rails_helper'

RSpec.describe Accounts::Apps::WppConnects::Webhooks::Messages::Onmessage, type: :request do
  describe 'success' do
    let(:account) { create(:account) }
    let(:wpp_connect) { create(:apps_wpp_connect)}
    let(:contact_response) { File.read("spec/integration/use_cases/accounts/apps/wpp_connects/webhooks/messages/onmessage/contact_response.json") }

    let(:event) { File.read("spec/integration/use_cases/accounts/apps/wpp_connects/webhooks/messages/onmessage/valid_event.json") }

    skip it do
      stub_request(:any, /contact/).
      to_return(body: contact_response, status: 200, headers: {'Content-Type' => 'application/json'})

      result = Accounts::Apps::WppConnects::Webhooks::Messages::Onmessage.call(wpp_connect, JSON.parse(event))
      expect(result.key?(:ok)).to eq(true)
    end
  end
end
