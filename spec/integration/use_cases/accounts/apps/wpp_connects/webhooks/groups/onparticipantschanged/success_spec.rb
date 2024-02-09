require 'rails_helper'

RSpec.describe Accounts::Apps::WppConnects::Webhooks::Groups::Onparticipantschanged, type: :request do
  describe 'success' do
    let(:account) { create(:account) }
    let(:wpp_connect) { create(:apps_wpp_connect)}
    let(:groups_response) { File.read("spec/integration/use_cases/accounts/apps/wpp_connects/sync/group/valid_event.json") }

    let(:event) { File.read("spec/integration/use_cases/accounts/apps/wpp_connects/webhooks/groups/onparticipantschanged/valid_event.json") }

    skip it do
      stub_request(:any, /all-groups/).
      to_return(body: groups_response, status: 200, headers: {'Content-Type' => 'application/json'})
      result = Accounts::Apps::WppConnects::Webhooks::Groups::Onparticipantschanged.call(wpp_connect, JSON.parse(event))
      expect(result.key?(:ok)).to eq(true)
    end
  end
end
