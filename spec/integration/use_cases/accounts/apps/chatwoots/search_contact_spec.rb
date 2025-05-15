require 'rails_helper'
require 'webmock/rspec'

RSpec.describe Accounts::Apps::Chatwoots::ExportContact, type: :request do
  describe '.call' do
    let(:account) { create(:account) }
    let(:chatwoot) { create(:apps_chatwoots, :skip_validate, account: account) }
    let(:contact) { create(:contact, account: account) }
    let(:response) do
      data = JSON.parse(File.read('spec/integration/use_cases/accounts/apps/chatwoots/search_contact.json'))
      data['payload'].first['email'] = contact.email
      data['payload'].first['name'] = contact.full_name
      data['payload'].first['phone_number'] = contact.phone
      data.to_json
    end

    it 'should return contact' do
      stub_request(:get, "#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/contacts/search").with(
        query: { q: contact[:email] },
        headers: chatwoot.request_headers
      )
        .to_return(body: response, status: 200, headers: { 'Content-Type' => 'application/json' })

      result = Accounts::Apps::Chatwoots::SearchContact.call(chatwoot, contact[:email])
      expect(result["email"]).to eq(contact[:email])
      expect(result["name"]).to eq(contact[:full_name])
    end

    it 'should not found contact' do
      stub_request(:get, "#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/contacts/search").with(
        query: { q: 'yuki@email.com' },
        headers: chatwoot.request_headers
      ).to_return(body: '{"meta":{"count":0,"current_page":"1"},"payload":[]}', status: 200, headers: { 'Content-Type' => 'application/json' })

      result = Accounts::Apps::Chatwoots::SearchContact.call(chatwoot, 'yuki@email.com')
      expect(result.key?(:error)).to eq(true)
    end
  end
end
