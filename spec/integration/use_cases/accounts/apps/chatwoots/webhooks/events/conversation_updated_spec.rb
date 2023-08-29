require 'rails_helper'

RSpec.describe Accounts::Apps::Chatwoots::Webhooks::Events::ConversationUpdated, type: :request do
  describe 'success' do
    let(:account) { create(:account) }
    let(:chatwoot) { create(:apps_chatwoots, :skip_validate)}
    let(:event) { File.read("spec/integration/use_cases/accounts/apps/chatwoots/webhooks/events/conversation_updated.json") }
    let(:contact_response) { File.read("spec/integration/use_cases/accounts/apps/chatwoots/webhooks/events/response_contact.json") }
    let(:response_conversations) { File.read("spec/integration/use_cases/accounts/apps/chatwoots/webhooks/events/response_conversations.json") }

    it do
      stub_request(:get, /contacts/).
      to_return(body: contact_response, status: 200, headers: {'Content-Type' => 'application/json'})
      stub_request(:get, /labels/).
      to_return(body: {"payload": ["testc"]}.to_json, status: 200, headers: {'Content-Type' => 'application/json'})
      stub_request(:get, /conversations/).
      to_return(body: response_conversations, status: 200, headers: {'Content-Type' => 'application/json'})

      result = Accounts::Apps::Chatwoots::Webhooks::Events::ConversationUpdated.call(chatwoot, JSON.parse(event))
      expect(result.key?(:ok)).to eq(true)
      expect(Contact.last.additional_attributes['chatwoot_id']).to eq(715)
    end
  end
end