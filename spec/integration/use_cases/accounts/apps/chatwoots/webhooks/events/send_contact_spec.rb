require 'rails_helper'
require 'webmock/rspec'

RSpec.describe Accounts::Apps::Chatwoots::Webhooks::SendContact, type: :request do
  describe 'success' do
    let(:chatwoot) { create(:apps_chatwoots, :skip_validate) }
    let(:contact_data) { attributes_for(:contact).to_json } 
    let(:contact_response) { { ok: 'contact created', chatwoot_id: 715 }.to_json }

    it 'sends contact data to Chatwoot API' do
      stub_request(:post, "#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/contacts")
        .to_return(body: contact_response, status: 200, headers: { 'Content-Type' => 'application/json' })

      expect {
        result = Accounts::Apps::Chatwoots::Webhooks::SendContact.call(chatwoot, contact_data)
        expect(result.key?(:ok)).to eq(true)
      }
    end
  end
end
