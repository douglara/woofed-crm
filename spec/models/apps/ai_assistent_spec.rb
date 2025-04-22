# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Apps::AiAssistent, type: :model do
  let!(:account) { create(:account, site_url: 'https://example.com') }
  let(:ai_assistent) { create(:apps_ai_assistent, enabled: false, usage: { 'tokens' => 50, 'limit' => 100 }) }

  describe '#embed_company_site' do
    before do
      allow(Current).to receive_message_chain(:account, :site_url).and_return('https://example.com')
    end

    context 'when enabled changes to true' do
      it 'enqueues the EmbedCompanySiteJob' do
        allow(Accounts::Create::EmbedCompanySiteJob).to receive(:perform_later)
        ai_assistent.update(enabled: true)
        expect(Accounts::Create::EmbedCompanySiteJob).to have_received(:perform_later).with(ai_assistent.id)
      end
    end

    context 'when api_key changes' do
      let(:ai_assistent) { create(:apps_ai_assistent, enabled: true, usage: { 'tokens' => 50, 'limit' => 100 }) }
      it 'enqueues the EmbedCompanySiteJob' do
        allow(Accounts::Create::EmbedCompanySiteJob).to receive(:perform_later)
        ai_assistent.update(api_key: 'new_api_key')
        expect(Accounts::Create::EmbedCompanySiteJob).to have_received(:perform_later).with(ai_assistent.id)
      end
    end

    context 'when Current.account.site_url is blank' do
      it 'does not enqueue the EmbedCompanySiteJob' do
        allow(Current).to receive_message_chain(:account, :site_url).and_return(nil)
        ai_assistent.update(enabled: true)
        expect(Accounts::Create::EmbedCompanySiteJob).not_to have_been_enqueued
      end
    end

    context 'when enabled is false' do
      it 'does not enqueue the EmbedCompanySiteJob' do
        ai_assistent.update(enabled: false)
        expect(Accounts::Create::EmbedCompanySiteJob).not_to have_been_enqueued
      end
    end
  end

  describe '#exceeded_usage_limit?' do
    context 'when usage limit is blank' do
      it 'returns false' do
        ai_assistent.usage['limit'] = nil
        expect(ai_assistent.exceeded_usage_limit?).to eq(false)
      end
    end

    context 'when tokens are below the limit' do
      it 'returns false' do
        ai_assistent.usage['tokens'] = 50
        ai_assistent.usage['limit'] = 100
        expect(ai_assistent.exceeded_usage_limit?).to eq(false)
      end
    end

    context 'when tokens are equal to the limit' do
      it 'returns true' do
        ai_assistent.usage['tokens'] = 100
        ai_assistent.usage['limit'] = 100
        expect(ai_assistent.exceeded_usage_limit?).to eq(true)
      end
    end

    context 'when tokens exceed the limit' do
      it 'returns true' do
        ai_assistent.usage['tokens'] = 150
        ai_assistent.usage['limit'] = 100
        expect(ai_assistent.exceeded_usage_limit?).to eq(true)
      end
    end

    context 'when usage is empty' do
      it 'returns false' do
        ai_assistent.usage = {}
        expect(ai_assistent.exceeded_usage_limit?).to eq(false)
      end
    end
  end
end
