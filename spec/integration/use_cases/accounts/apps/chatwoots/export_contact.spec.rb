require 'rails_helper'
require 'webmock/rspec'

RSpec.describe Accounts::Apps::Chatwoots::Webhooks::ExportContact, type: :request do
  describe 'success' do
    let(:account) { create(:account) }
    let(:chatwoot) { create(:apps_chatwoots, :skip_validate, account: account) }
    let(:contact) { create(:contact, account: account) }
    let(:contact_chatwoot_id) { create(:contact, account: account, additional_attributes: {'chatwoot_id': 1}) }
    let(:contact_create_response) do
        {
          "payload": {
            "contact": {
              "additional_attributes": {},
              "availability_status": "offline",
              "email": "tim@maia.com",
              "id": 368,
              "name": "Tim Maia",
              "phone_number": "",
              "identifier": nil,
              "thumbnail": "",
              "custom_attributes": {
                "CPF": "",
                "Cpf": "",
                "cep": "",
                "Cnpj": "",
                "TEste": "",
                "hgfhfgh": "",
                "Endereço de casa": ""
              },
              "created_at": 1701324831,
              "contact_inboxes": []
            },
            "contact_inbox": {
              "inbox": nil,
              "source_id": nil
            }
          }
        }
      end

    let(:contact_update_response) { {
        "name": "Tim Maia",
        "email": "tim@maia.com",
        "phone_number": "+5541988443322",
        "custom_attributes": {},
        "additional_attributes": {'chatwoot_id': 1}
    } }
    

    it 'export contact data to Chatwoot API' do
      stub_request(:post, "#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/contacts")
        .to_return(body: contact_create_response.to_json, status: 200, headers: { 'Content-Type' => 'application/json' })

      result = Accounts::Apps::Chatwoots::Webhooks::ExportContact.call(chatwoot, contact)
      expect(result.key?(:ok)).to eq(true)
    end
    it 'update contact in Chatwoot API' do
        stub_request(:put, "#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/contacts/#{contact_chatwoot_id.additional_attributes['chatwoot_id']}")
            .to_return(body: contact_update_response.to_json, status: 200, headers: { 'Content-Type' => 'application/json' })

        result = Accounts::Apps::Chatwoots::Webhooks::ExportContact.call(chatwoot, contact_chatwoot_id)
        expect(result.key?(:ok)).to eq(true)
    end

    it 'create contact with email that already exists on Chatwoot API' do
      stub_request(:post, "#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/contacts")
        .to_return(body: {"message": "Email has already been taken", "attributes": ["email"]}.to_json, status: 422, headers: { 'Content-Type' => 'application/json' })

      result = Accounts::Apps::Chatwoots::Webhooks::ExportContact.call(chatwoot, contact)
      expect(result.key?(:error)).to eq(true)
    end
  end
end
