require 'rails_helper'

RSpec.describe Accounts::Apps::Chatwoots::Webhooks::Events::Message, type: :request do
  describe 'success' do
    let(:account) { create(:account) }
    let(:chatwoot) { create(:apps_chatwoots, :skip_validate)}
    let(:event_message_sent) { File.read("spec/integration/use_cases/accounts/apps/chatwoots/webhooks/events/message/event_message_sent.json") }
    let(:event_message_receive) { File.read("spec/integration/use_cases/accounts/apps/chatwoots/webhooks/events/message/event_message_receive.json") }
    let(:contact_response) { File.read("spec/integration/use_cases/accounts/apps/chatwoots/webhooks/events/response_contact.json") }
    let(:response_conversations) { File.read("spec/integration/use_cases/accounts/apps/chatwoots/webhooks/events/response_conversations.json") }

    context "receive event" do
      before do
        stub_request(:get, /contacts/).
        to_return(body: contact_response, status: 200, headers: {'Content-Type' => 'application/json'})
        stub_request(:get, /labels/).
        to_return(body: {"payload": ["testc"]}.to_json, status: 200, headers: {'Content-Type' => 'application/json'})
        stub_request(:get, /conversations/).
        to_return(body: response_conversations, status: 200, headers: {'Content-Type' => 'application/json'})
      end

      it 'import event about chatwoot send message' do
        result = Accounts::Apps::Chatwoots::Webhooks::Events::Message.call(chatwoot, JSON.parse(event_message_sent))
        expect(result.key?(:ok)).to eq(true)
        expect(Event.last.content.body.to_plain_text).to eq('Teste2')
        expect(Event.last.from_me).to eq(true)
        expect(Event.last.done).to eq(true)
        expect(Event.last.kind).to eq('chatwoot_message')
        expect(Event.last.done_at).to eq("2023-07-26T01:59:54.994Z")
      end
      it 'import event about chatwoot receive message' do
        result = Accounts::Apps::Chatwoots::Webhooks::Events::Message.call(chatwoot, JSON.parse(event_message_receive))
        expect(result.key?(:ok)).to eq(true)
        expect(Event.last.content.body.to_plain_text).to eq('teste receive')
        expect(Event.last.from_me).to eq(false)
      end
    end
  end
end
