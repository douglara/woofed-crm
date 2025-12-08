# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Accounts::Apps::Chatwoots::Webhooks::ProcessWebhook do
  let(:account) { create(:account) }
  let(:webhook_data) { { 'token' => 'test_token', 'event' => 'contact_created' } }

  describe '.call' do
    context 'when chatwoot integration is not found' do
      it 'returns error' do
        result = described_class.call(webhook_data)
        expect(result).to eq({ error: 'Chatwoot integration not found' })
      end
    end

    context 'when chatwoot integration is inactive' do
      let!(:chatwoot) { create(:apps_chatwoots, :inactive, :skip_validate, embedding_token: 'test_token', account: account) }

      it 'returns error' do
        result = described_class.call(webhook_data)
        expect(result).to eq({ error: 'Chatwoot integration inactive' })
      end
    end

    context 'when chatwoot integration is active' do
      let!(:chatwoot) { create(:apps_chatwoots, :skip_validate, embedding_token: 'test_token', account:) }

      before do
        allow(Accounts::Apps::Chatwoots::Webhooks::Events::Contact).to receive(:call)
      end

      it 'processes the webhook successfully' do
        result = described_class.call(webhook_data)
        expect(result).to eq({ ok: chatwoot })
      end

      it 'calls the appropriate event handler' do
        expect(Accounts::Apps::Chatwoots::Webhooks::Events::Contact).to receive(:call).with(chatwoot, webhook_data)
        described_class.call(webhook_data)
      end
    end
  end
end
