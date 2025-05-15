require 'rails_helper'

RSpec.describe Accounts::Apps::Chatwoots::GetConversations, type: :request do
  describe 'success' do
    let(:account) { create(:account) }
    let(:chatwoot) { create(:apps_chatwoots, :skip_validate) }
    let(:conversation_response) do
      File.read('spec/integration/use_cases/accounts/apps/chatwoots/get_conversations.json')
    end

    it do
      stub_request(:get, /conversations/)
        .to_return(body: conversation_response, status: 200, headers: { 'Content-Type' => 'application/json' })

      result = Accounts::Apps::Chatwoots::GetConversations.call(chatwoot, 2, 2)
      expect(result[:ok][0]['id']).to eq(2)
      expect(result[:ok].count).to eq(7)
    end
    context 'when inbox_id param is nil' do
      it 'should return all conversations' do
        stub_request(:get, /conversations/)
        .to_return(body: conversation_response, status: 200, headers: { 'Content-Type' => 'application/json' })

      result = Accounts::Apps::Chatwoots::GetConversations.call(chatwoot, 2, nil)
      expect(result[:ok][0]['id']).to eq(2)
      expect(result[:ok].count).to eq(8)
      end
    end
  end
end
