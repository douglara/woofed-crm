require 'rails_helper'

RSpec.describe Accounts::Apps::Chatwoots::CreateConversation, type: :request do
  describe 'success' do
    let(:account) { create(:account) }
    let(:chatwoot) { create(:apps_chatwoots, :skip_validate)}
    let(:conversation_response) { File.read("spec/integration/use_cases/accounts/apps/chatwoots/create_conversation.json") }

    it do
      stub_request(:post, /conversations/).
      to_return(body: conversation_response, status: 200, headers: {'Content-Type' => 'application/json'})

      result = Accounts::Apps::Chatwoots::CreateConversation.call(chatwoot, 2, 2)
      expect(result[:ok]['id']).to eq(10)
    end
  end
end
