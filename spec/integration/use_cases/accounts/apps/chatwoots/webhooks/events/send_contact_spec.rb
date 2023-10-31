require 'rails_helper'
require 'webmock/rspec'

RSpec.describe Accounts::Apps::Chatwoots::Webhooks::SendContact, type: :request do
  describe 'success' do
    let(:account) { create(:account) }
    let(:chatwoot) { create(:apps_chatwoots, :skip_validate, account: account) }
    let(:contact) { create(:contact, account: account) }
    let(:contact_response) { '{"account":{"id":3,"name":"Doug testes"},"additional_attributes":{"city":"","country":"","description":"","company_name":"","country_code":"","social_profiles":{"github":"","twitter":"","facebook":"","linkedin":"","instagram":""}},"avatar":"","custom_attributes":{},"email":"roberiojr@gmail.com","id":130,"identifier":null,"name":"Roberio","phone_number":"+5573991817179","thumbnail":"","event":"contact_created"}' }

    it 'sends contact data to Chatwoot API' do
      stub_request(:post, "#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/contacts")
        .to_return(body: contact_response, status: 200, headers: { 'Content-Type' => 'application/json' })

      result = Accounts::Apps::Chatwoots::Webhooks::SendContact.call(chatwoot, contact)
      expect(result.key?(:ok)).to eq(true)
    end

    it 'invalid contact params' do
      stub_request(:post, "#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/contacts")
        .to_return(body: '', status: 400, headers: { 'Content-Type' => 'application/json' })

      result = Accounts::Apps::Chatwoots::Webhooks::SendContact.call(chatwoot, contact)
      expect(result.key?(:error)).to eq(true)
    end
  end
end
