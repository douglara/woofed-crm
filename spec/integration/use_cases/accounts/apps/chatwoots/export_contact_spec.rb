require 'rails_helper'
require 'webmock/rspec'

RSpec.describe Accounts::Apps::Chatwoots::ExportContact, type: :request do
  describe '.call' do
    let(:account) { create(:account) }
    let(:chatwoot) { create(:apps_chatwoots, :skip_validate, account: account) }
    let(:contact) { create(:contact, account: account) }
    let(:contact_chatwoot_id) { create(:contact, account: account, additional_attributes: {'chatwoot_id': 1}) }

    describe 'success' do
      let(:search_contact_query_response)  { File.read("spec/integration/use_cases/accounts/apps/chatwoots/search_contact.json") }
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
        stub_request(:post, "#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/contacts/#{contact_create_response[:payload][:contact][:id]}/labels")
        .to_return(body: {payload: []}.to_json, status: 200, headers: { 'Content-Type' => 'application/json' })
        result = Accounts::Apps::Chatwoots::ExportContact.call(chatwoot, contact)
        expect(result.key?(:ok)).to eq(true)
      end

      it 'update contact in Chatwoot API' do
        stub_request(:put, "#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/contacts/#{contact_chatwoot_id.additional_attributes['chatwoot_id']}")
        .to_return(body: contact_update_response.to_json, status: 200, headers: { 'Content-Type' => 'application/json' })
        stub_request(:post, "#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/contacts/#{contact_update_response[:additional_attributes][:chatwoot_id]}/labels")
        .to_return(body: {payload: []}.to_json, status: 200, headers: { 'Content-Type' => 'application/json' })

        result = Accounts::Apps::Chatwoots::ExportContact.call(chatwoot, contact_chatwoot_id)
        expect(result.key?(:ok)).to eq(true)
      end

      it 'create contact with email that already exists on Chatwoot API' do
        stub_request(:post, "#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/contacts")
        .to_return(body: {"message": "Email has already been taken", "attributes": ["email"]}.to_json, status: 422, headers: { 'Content-Type' => 'application/json' })

        stub_request(:get, "#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/contacts/search").with(
          query: { q: contact[:email] },
          headers: chatwoot.request_headers
        )
        .to_return(body: search_contact_query_response, status: 200, headers: { 'Content-Type' => 'application/json' })
        stub_request(:post, "#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/contacts/#{JSON.parse(search_contact_query_response)['payload'].first['id']}/labels")
        .to_return(body: {payload: []}.to_json, status: 200, headers: { 'Content-Type' => 'application/json' })

        result = Accounts::Apps::Chatwoots::ExportContact.call(chatwoot, contact)
        expect(result.key?(:ok)).to eq(true)
        expect(result[:ok][:additional_attributes]['chatwoot_id']).to eq(contact[:additional_attributes]['chatwoot_id'])
      end

      it 'create contact with phone number that already exists on Chatwoot API' do
        stub_request(:post, "#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/contacts")
        .to_return(body: {"message"=>"Phone number has already been taken", "attributes"=>["phone_number"]}.to_json, status: 422, headers: { 'Content-Type' => 'application/json' })

        stub_request(:get, "#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/contacts/search").with(
          query: { q: contact[:phone] },
          headers: chatwoot.request_headers
        )
        .to_return(body: search_contact_query_response, status: 200, headers: { 'Content-Type' => 'application/json' })
        stub_request(:post, "#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/contacts/#{JSON.parse(search_contact_query_response)['payload'].first['id']}/labels")
        .to_return(body: {payload: []}.to_json, status: 200, headers: { 'Content-Type' => 'application/json' })

        result = Accounts::Apps::Chatwoots::ExportContact.call(chatwoot, contact)
        expect(result.key?(:ok)).to eq(true)
        expect(result[:ok][:additional_attributes]['chatwoot_id']).to eq(contact[:additional_attributes]['chatwoot_id'])
      end
      context 'when contact contains labels' do
        let(:contact) { create(:contact, account: account, label_list: ['marcador1', 'marcador2']) }
        it do
        stub_request(:post, "#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/contacts")
        .to_return(body: contact_create_response.to_json, status: 200, headers: { 'Content-Type' => 'application/json' })
        stub_request(:post, "#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/contacts/#{contact_create_response[:payload][:contact][:id]}/labels")
        .to_return(body: {payload: ['marcador1', 'marcador2']}.to_json, status: 200, headers: { 'Content-Type' => 'application/json' })
        result = Accounts::Apps::Chatwoots::ExportContact.call(chatwoot, contact)
        expect(result.key?(:ok)).to eq(true)
        expect(result[:ok][:label_list]).to eq(['marcador1', 'marcador2'])
        end
      end
    end

    describe 'should failed' do
      it 'should error create contact with invalid email' do
        contact.update_column(:email, 'invalid_email')
        stub_request(:post, "#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/contacts")
        .to_return(body: '{"message":"Email Invalid email","attributes":["email"]}', status: 422, headers: { 'Content-Type' => 'application/json' })
        result = Accounts::Apps::Chatwoots::ExportContact.call(chatwoot, contact)
        expect(result.key?(:error)).to eq(true)
      end

      it 'should error in update contact with invalid email' do
        contact.update_columns({email: 'invalid_email', additional_attributes: {'chatwoot_id': 1}})
        stub_request(:put, "#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/contacts/1")
        .to_return(body: '{"message":"Email Invalid email","attributes":["email"]}', status: 422, headers: { 'Content-Type' => 'application/json' })
        result = Accounts::Apps::Chatwoots::ExportContact.call(chatwoot, contact)
        expect(result.key?(:error)).to eq(true)
      end
    end
  end
end
