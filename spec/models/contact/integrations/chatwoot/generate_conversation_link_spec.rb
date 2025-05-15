require 'rails_helper'

RSpec.describe Contact::Integrations::Chatwoot::GenerateConversationLink do
  let(:account) { create(:account) }
  let(:contact) { create(:contact, additional_attributes: { 'chatwoot_id' => '123' }) }
  let(:chatwoot) { create(:apps_chatwoots, chatwoot_account_id: '456', chatwoot_endpoint_url: 'https://chatwoot.example.com/') }
  let(:subject) { described_class.new(contact) }

  describe '#call' do
    context 'when all conditions are met' do
      before do
        allow(Accounts::Apps::Chatwoots::GetConversations).to receive(:call)
          .with(chatwoot, '123')
          .and_return(ok: [{ 'id' => '789' }])
      end

      it 'returns a hash with the conversation URL' do
        expected_url = 'https://chatwoot.example.com/app/accounts/456/conversations/789'
        expect(subject.call).to eq(ok: expected_url)
      end
    end

    context 'when chatwoot is not found' do
      before do
        allow(Apps::Chatwoot.first).to receive(:apps_chatwoots).and_return([])
      end

      it 'returns an error hash and logs a warning' do
        expect(subject.call).to eq(error: 'no_chatwoot_or_id')
      end
    end

    context 'when chatwoot_contact_id is missing' do
      let(:contact) { create(:contact, account:, additional_attributes: {}) }

      it 'returns an error hash and logs a warning' do
        expect(subject.call).to eq(error: 'no_chatwoot_or_id')
      end
    end

    context 'when no conversations are found' do
      before do
        allow(Accounts::Apps::Chatwoots::GetConversations).to receive(:call)
          .with(chatwoot, '123')
          .and_return(ok: [])
      end

      it 'returns an error hash and logs a warning' do
        expect(subject.call).to eq(error: 'no_conversation')
      end
    end

    context 'when GetConversations raises a Faraday::TimeoutError' do
      before do
        allow(Accounts::Apps::Chatwoots::GetConversations).to receive(:call)
          .with(chatwoot, '123')
          .and_raise(Faraday::TimeoutError)
      end

      it 'raises the error' do
        expect { subject.call }.to raise_error(Faraday::TimeoutError)
      end
    end
  end
end
