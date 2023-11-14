require 'rails_helper'

RSpec.describe Accounts::Apps::Chatwoots::GetInboxes, type: :request do
  let(:account) { create(:account, ) }
  let(:chatwoot) { create(:apps_chatwoots, :skip_validate)}
  let(:inboxes_response) { File.read("spec/integration/use_cases/accounts/apps/chatwoots/inboxes.json") }

  describe 'success' do
    it do
      stub_request(:get, /inboxes/).
      to_return(body: inboxes_response, status: 200, headers: {'Content-Type' => 'application/json'})

      result = Accounts::Apps::Chatwoots::GetInboxes.call(chatwoot)
      expect(result.key?(:ok)).to eq(true)
    end
  end

  describe 'should raise error' do
    it do
      stub_request(:get, /inboxes/).
      to_return(body: '', status: 504, headers: {'Content-Type' => 'application/json'})

      expect {
        Accounts::Apps::Chatwoots::GetInboxes.call(chatwoot)
      }.to raise_error(JSON::ParserError)
    end
  end
end