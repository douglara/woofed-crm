require 'rails_helper'

RSpec.describe Accounts::Apps::Chatwoots::SendMessage, type: :request do
  describe 'success' do
    let(:account) { create(:account) }
    let(:chatwoot) { create(:apps_chatwoots, :skip_validate)}
    let(:response) { File.read("spec/integration/use_cases/accounts/apps/chatwoots/send_message.json") }

    it do
      stub_request(:post, /messages/).
      to_return(body: response, status: 200, headers: {'Content-Type' => 'application/json'})

      result = Accounts::Apps::Chatwoots::SendMessage.call(chatwoot, 10, 'Hi Lorena')
      expect(result[:ok]['id']).to eq(227)
    end
  end
end
