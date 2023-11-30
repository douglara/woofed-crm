require 'rails_helper'

RSpec.describe Accounts::Apps::Chatwoots::Webhooks::Events::Contact, type: :request do
  describe 'success' do
    let(:account) { create(:account) }
    let(:chatwoot) { create(:apps_chatwoots, :skip_validate, account: account)}
    let(:event) { File.read("spec/integration/use_cases/accounts/apps/chatwoots/webhooks/events/contact/contact_created.json") }
    let(:contact_response) { File.read("spec/integration/use_cases/accounts/apps/chatwoots/webhooks/events/contact/contact_request_response.json") }
    let(:response_conversations) { File.read("spec/integration/use_cases/accounts/apps/chatwoots/webhooks/events/response_conversations.json") }

    before do
      stub_request(:get, /contacts/).
      to_return(body: contact_response, status: 200, headers: {'Content-Type' => 'application/json'})
      stub_request(:get, /labels/).
      to_return(body: {"payload": ["testc"]}.to_json, status: 200, headers: {'Content-Type' => 'application/json'})
      stub_request(:get, /conversations/).
      to_return(body: response_conversations, status: 200, headers: {'Content-Type' => 'application/json'})
    end

    it 'create contact' do
      result = described_class.call(chatwoot, JSON.parse(event))
      expect(result.key?(:ok)).to eq(true)
      contact = Contact.last
      expect(contact.additional_attributes['chatwoot_id']).to eq(224)
      expect(contact.custom_attributes['cpf']).to eq('1234')
    end

    context 'update contact' do
      it 'should update' do
        contact = create(:contact, account: account, additional_attributes: {'chatwoot_id': 224})
        result = described_class.call(chatwoot, JSON.parse(event))
        expect(result.key?(:ok)).to eq(true)
        expect(contact.reload.additional_attributes['chatwoot_id']).to eq(224)
        expect(contact.custom_attributes['cpf']).to eq('1234')
      end

      it 'contact not found in chatwoot' do
        stub_request(:get, /contacts/).
        to_return(body: '{"error":"Resource could not be found"}', status: 404, headers: {'Content-Type' => 'application/json'})

        contact = create(:contact, account: account, additional_attributes: {'chatwoot_id': 224})
        result = described_class.call(chatwoot, JSON.parse(event))
        expect(result[:ok]).to eq('Contact not found')
      end
    end
  end
end
