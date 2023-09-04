require 'rails_helper'

RSpec.describe Accounts::Apps::WppConnects::Sync::Group, type: :request do
  describe 'success' do
    let(:account) { create(:account) }
    let(:wpp_connect) { create(:apps_wpp_connect)}
    let(:event) { File.read("spec/integration/use_cases/accounts/apps/wpp_connects/sync/group/valid_event.json") }

    it do
      stub_request(:any, /all-groups/).
      to_return(body: event, status: 200, headers: {'Content-Type' => 'application/json'})
      result = Accounts::Apps::WppConnects::Sync::Group.call(wpp_connect, '120363101980547250')
      expect(result.key?(:ok)).to eq(true)
    end
  end
end
