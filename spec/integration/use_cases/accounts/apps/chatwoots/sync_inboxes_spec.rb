require 'rails_helper'

RSpec.describe Accounts::Apps::Chatwoots::GetInboxes, type: :request do
  let(:account) { create(:account) }
  let(:chatwoot) { create(:apps_chatwoots, :skip_validate) }
  let(:inboxes_response) { File.read('spec/integration/use_cases/accounts/apps/chatwoots/inboxes.json') }

  describe 'success' do
    it do
      stub_request(:get, /inboxes/)
        .to_return(body: inboxes_response, status: 200, headers: { 'Content-Type' => 'application/json' })

      result = Accounts::Apps::Chatwoots::GetInboxes.call(chatwoot)
      expect(result.key?(:ok)).to eq(true)
    end
  end

  describe 'failed' do
    it do
      stub_request(:get, /inboxes/)
        .to_return(body: '{"error":"Account is suspended"}', status: 401, headers: { 'Content-Type' => 'application/json' })

      result = Accounts::Apps::Chatwoots::GetInboxes.call(chatwoot)
      expect(result.key?(:error)).to be_truthy
    end
  end
end
