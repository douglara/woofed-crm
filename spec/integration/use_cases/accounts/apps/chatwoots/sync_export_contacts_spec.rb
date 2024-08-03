require 'rails_helper'
require 'webmock/rspec'
require 'sidekiq/testing'

RSpec.describe Accounts::Apps::Chatwoots::SyncExportContacts, type: :request do
  describe '.call' do
    let!(:account) { create(:account) }
    let!(:chatwoot) { create(:apps_chatwoots, :skip_validate, account: account) }
    let!(:contact_1) do
      create(:contact, account: account, additional_attributes: { 'chatwoot_id': 1 }, full_name: 'teste',
                       email: 'emailteste@email.com')
    end
    let!(:contact_2) { create(:contact, account: account) }
    let(:contact_update_response) do
      {
        "id": 368,
        "payload": {
          "contact": {
            "additional_attributes": {},
            "availability_status": 'offline',
            "email": 'tim@maia.com',
            "name": 'Tim Maia',
            "phone_number": '',
            "thumbnail": '',
            "custom_attributes": {
              "CPF": '',
              "Cpf": '',
              "cep": '',
              "Cnpj": '',
              "TEste": '',
              "hgfhfgh": '',
              "Endereço de casa": ''
            },
            "contact_inbox": {
              "inbox": nil,
              "source_id": nil
            }
          }
        }
      }
    end
    let(:contact_create_response) do
      {
        "payload": {
          "contact": {
            "additional_attributes": {},
            "availability_status": 'offline',
            "email": 'tim@maia.com',
            "id": 368,
            "name": 'Tim Maia',
            "phone_number": '',
            "identifier": nil,
            "thumbnail": '',
            "custom_attributes": {
              "CPF": '',
              "Cpf": '',
              "cep": '',
              "Cnpj": '',
              "TEste": '',
              "hgfhfgh": '',
              "Endereço de casa": ''
            },
            "created_at": 1_701_324_831,
            "contact_inboxes": []
          },
          "contact_inbox": {
            "inbox": nil,
            "source_id": nil
          }
        }
      }
    end

    describe 'success' do
      before do
        stub_request(:post, "#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/contacts")
          .to_return(body: contact_create_response.to_json, status: 200, headers: { 'Content-Type' => 'application/json' })
        stub_request(:put, "#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/contacts/#{contact_create_response[:payload][:contact][:id]}")
          .to_return(body: contact_update_response.to_json, status: 200, headers: { 'Content-Type' => 'application/json' })
        stub_request(:post, /labels/)
          .to_return(body: {}.to_json, status: 200, headers: { 'Content-Type' => 'application/json' })
      end
      before(:each) do
        allow_any_instance_of(Object).to receive(:sleep)
      end
      it 'Export contact data to Chatwoot API' do
        Accounts::Apps::Chatwoots::SyncExportContacts.call(account)
        expect(account.contacts.count).to eq(2)
        expect(account.contacts.where("additional_attributes -> 'chatwoot_id' IS NOT NULL").count).to eq(2)
      end
    end
  end
end
