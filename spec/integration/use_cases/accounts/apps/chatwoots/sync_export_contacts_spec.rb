require 'rails_helper'
require 'webmock/rspec'

RSpec.describe Accounts::Apps::Chatwoots::SyncExportContacts, type: :request do
  describe '.call' do
    let!(:account) { create(:account) }
    let!(:chatwoot) { create(:apps_chatwoots, :skip_validate, account: account) }
    let!(:contact_1) { create(:contact, account: account, additional_attributes: {'chatwoot_id': 1}, full_name:'teste', email: 'emailteste@email.com') }
    let!(:contact_2) { create(:contact, account: account) }
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

    describe 'success' do
      before do 
        stub_request(:post, "#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/contacts")
        .to_return(body: contact_create_response.to_json, status: 200, headers: { 'Content-Type' => 'application/json' })
      end
      it 'Export contact data to Chatwoot API' do
        result = Accounts::Apps::Chatwoots::SyncExportContacts.call(account)
        expect(result.key?(:ok)).to eq(true)
        expect(account.contacts.count).to eq(2)
      end
    end
  end
end
