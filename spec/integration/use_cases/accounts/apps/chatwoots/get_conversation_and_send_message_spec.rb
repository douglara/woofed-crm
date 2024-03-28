require 'rails_helper'

RSpec.describe Accounts::Apps::Chatwoots::GetConversationAndSendMessage, type: :request do
  describe 'success' do
    let(:account) { create(:account) }
    let(:chatwoot) { create(:apps_chatwoots, :skip_validate) }
    let(:event) { create(:event) }
    let(:conversation_response) do
      File.read('spec/integration/use_cases/accounts/apps/chatwoots/get_conversations.json')
    end
    let(:message_response) { File.read('spec/integration/use_cases/accounts/apps/chatwoots/send_message.json') }

    it 'should have conversation' do
      stub_request(:post, /messages/)
        .to_return(body: message_response, status: 200, headers: { 'Content-Type' => 'application/json' })
      stub_request(:post, /filter/)
        .to_return(body: conversation_response, status: 200, headers: { 'Content-Type' => 'application/json' })

      result = Accounts::Apps::Chatwoots::GetConversationAndSendMessage.call(chatwoot, 2, 2, event)
      expect(result[:ok]['id']).to eq(227)
    end
  end
end
