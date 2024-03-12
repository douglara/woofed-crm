require 'rails_helper'

RSpec.describe Accounts::Apps::Chatwoots::Webhooks::Events::Message, type: :request do
  describe 'success' do
    let(:account) { create(:account) }
    let(:chatwoot) { create(:apps_chatwoots, :skip_validate)}
    let(:event_message_sent) { File.read("spec/integration/use_cases/accounts/apps/chatwoots/webhooks/events/message/event_message_sent.json") }
    let(:event_message_receive) { File.read("spec/integration/use_cases/accounts/apps/chatwoots/webhooks/events/message/event_message_receive.json") }
    let(:contact_response) { File.read("spec/integration/use_cases/accounts/apps/chatwoots/webhooks/events/response_contact.json") }
    let(:response_conversations) { File.read("spec/integration/use_cases/accounts/apps/chatwoots/webhooks/events/response_conversations.json") }
    let(:event_first) { Event.first}

    context "receive event without attachment" do
      before do
        stub_request(:get, /contacts/).
        to_return(body: contact_response, status: 200, headers: {'Content-Type' => 'application/json'})
        stub_request(:get, /labels/).
        to_return(body: {"payload": ["testc"]}.to_json, status: 200, headers: {'Content-Type' => 'application/json'})
        stub_request(:get, /conversations/).
        to_return(body: response_conversations, status: 200, headers: {'Content-Type' => 'application/json'})
      end

      it 'import event chatwoot send message' do
        result = described_class.call(chatwoot, JSON.parse(event_message_sent))
        expect(result.key?(:ok)).to eq(true)
        expect(event_first.content).to eq('Teste2')
        expect(event_first.from_me).to eq(true)
        expect(event_first.done).to eq(true)
        expect(event_first.kind).to eq('chatwoot_message')
        expect(event_first.done_at).to eq("2023-07-26T01:59:54.994Z")
        expect(event_first.additional_attributes).to include({'chatwoot_id' => 99523})
      end
      it 'import event chatwoot receive message' do
        result = described_class.call(chatwoot, JSON.parse(event_message_receive))
        expect(result.key?(:ok)).to eq(true)
        expect(event_first.content).to eq('teste receive')
        expect(event_first.from_me).to eq(false)
        expect(event_first.additional_attributes).to include({'chatwoot_id' => 3750})
      end
    end
    context 'receive event with attachment' do
      before do
        stub_request(:get, /contacts/).
        to_return(body: contact_response, status: 200, headers: {'Content-Type' => 'application/json'})
        stub_request(:get, /labels/).
        to_return(body: {"payload": ["testc"]}.to_json, status: 200, headers: {'Content-Type' => 'application/json'})
        stub_request(:get, /conversations/).
        to_return(body: response_conversations, status: 200, headers: {'Content-Type' => 'application/json'})
        stub_request(:any, /chatwoot\.server3\.woofedcrm\.com/).
        to_return(body: 'file data')
      end
      context 'when receive event with one attachment' do
        let(:event_message_with_one_attachment) { File. read("spec/integration/use_cases/accounts/apps/chatwoots/webhooks/events/message/event_message_with_one_attachment.json") }
        it 'should crete one event with one attachment' do
          expect do
            described_class.call(chatwoot, JSON.parse(event_message_with_one_attachment))
          end.to change(Event, :count).by(1)
          expect(event_first.additional_attributes).to include({'chatwoot_id' => 8633})
          expect(Attachment.count).to eq(1)
        end
      end
      context 'when receive event with more than one attachment' do
        let(:event_message_with_three_attachments) { File. read("spec/integration/use_cases/accounts/apps/chatwoots/webhooks/events/message/event_message_with_three_attachments.json") }
        it 'should create 3 events and 3 attachments' do
          expect do
            described_class.call(chatwoot, JSON.parse(event_message_with_three_attachments))
          end.to change(Event, :count).by(3)
          expect(Event.last.attachment.file.filename.to_s).to eq("bob_esponja.png")
          expect(Event.last.content).to eq("Message with attachments")
          expect(Event.first.attachment.file.filename.to_s).to eq("lula.png")
          expect(Event.first.content.to_plain_text).to eq("")
          expect(Event.all.map(&:additional_attributes)).to include({'chatwoot_id' => 8637}).exactly(Event.count).times
          expect(Attachment.count).to eq(3)
        end
      end

      context 'when receive event with not found attachment' do
        let(:event_message_with_one_attachment) { File. read("spec/integration/use_cases/accounts/apps/chatwoots/webhooks/events/message/event_message_with_one_attachment.json") }

        it 'should crete one event with one attachment' do
          stub_request(:any, /chatwoot\.server3\.woofedcrm\.com/).
          to_return(status: 404)

          expect do
            described_class.call(chatwoot, JSON.parse(event_message_with_one_attachment))
          end.to change(Event, :count).by(1)
          expect(event_first.additional_attributes).to include({'chatwoot_id' => 8633})
          expect(event_first.status).to eq('failed')
          expect(Attachment.count).to eq(0)
        end
      end
    end
  end
end
