require 'rails_helper'
require 'webmock/rspec'

RSpec.describe Accounts::Apps::Chatwoots::ExportContact, type: :request do
  describe 'success' do
    let(:account) { create(:account) }
    let(:chatwoot) { create(:apps_chatwoots, :skip_validate, account: account) }
    let(:response) { File.read("spec/integration/use_cases/accounts/apps/chatwoots/search_contact.json") }
    

    let(:contact_serch_params) { {
        "name": "Yukio Pinheiro Arie",
        "email": "yukioarie@gmail.com",
        "phone_number": "+5541988443322",
    } }
    

    it 'Chatwoot API search contact' do
      stub_request(:get, "#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/contacts/search").with(
        query: { q: contact_serch_params[:email] },
        headers: chatwoot.request_headers
      )
        .to_return(body: response, status: 200, headers: { 'Content-Type' => 'application/json' })

      result = Accounts::Apps::Chatwoots::SearchContact.call(chatwoot, contact_serch_params[:email])
      expect(result["email"]).to eq(contact_serch_params[:email])
      expect(result["name"]).to eq(contact_serch_params[:name])
    end

    it 'Chatwoot API seach contact not found' do
        stub_request(:get, "#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/contacts/search").with(
          query: { q: 'yuki@email.com' },
          headers: chatwoot.request_headers
        )
          .to_return(body: {error: "Contact not found"}.to_json, status: 200, headers: { 'Content-Type' => 'application/json' })
          result = Accounts::Apps::Chatwoots::SearchContact.call(chatwoot, 'yuki@email.com')
          expect(result.key?(:error)).to eq(true)
        
      end
  end
end
