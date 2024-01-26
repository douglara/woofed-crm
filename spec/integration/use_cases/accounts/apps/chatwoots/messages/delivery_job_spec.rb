require 'rails_helper'

RSpec.describe Accounts::Apps::Chatwoots::CreateConversation, type: :request do
  describe 'success' do
    let(:account) { create(:account) }
    let(:chatwoot) { create(:apps_chatwoots, :skip_validate)}
    let(:event) { create(:event, app: chatwoot, account: account, content: 'Hi Lorena', from_me: true, scheduled_at: Time.now, kind: 'chatwoot_message')}

    let(:conversation_response) { File.read("spec/integration/use_cases/accounts/apps/chatwoots/get_conversations.json") }
    let(:message_response) { File.read("spec/integration/use_cases/accounts/apps/chatwoots/send_message.json") }

    it do
      stub_request(:post, /filter/).
      to_return(body: conversation_response, status: 200, headers: {'Content-Type' => 'application/json'})
      stub_request(:post, /messages/).
      to_return(body: message_response, status: 200, headers: {'Content-Type' => 'application/json'})

      result = Accounts::Apps::Chatwoots::Messages::DeliveryJob.perform_now(event.id)

      expect(result[:ok].additional_attributes['chatwoot_id']).to eq(227)
    end
  end
end
