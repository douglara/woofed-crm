require 'rails_helper'

RSpec.describe Accounts::Apps::Chatwoots::GetConversations, type: :request do
  describe 'success' do
    let(:account) { create(:account) }
    let(:chatwoot) { create(:apps_chatwoots, :skip_validate)}
    let(:conversation_response) { File.read("spec/integration/use_cases/accounts/apps/chatwoots/get_conversations.json") }

    it do
      stub_request(:post, /conversations/).
      to_return(body: conversation_response, status: 200, headers: {'Content-Type' => 'application/json'})

      result = Accounts::Apps::Chatwoots::GetConversations.call(chatwoot, 2, 2)
      expect(result[:ok][0]['id']).to eq(2)
    end
  end
end
