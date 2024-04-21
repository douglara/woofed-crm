require 'rails_helper'
require 'sidekiq/testing'

describe WebhookListener do
  # include ActiveJob::TestHelper

  describe '#deal_updated' do
    let!(:account) { create(:account) }
    let!(:webhook) { create(:webhook, account: account) }
    let!(:deal) { create(:deal, account: account) }

    it 'adds system users' do
      expect {
        deal.update(name: 'new_name')
      }.to change(WebhookWorker.jobs, :size).by(1)
    end
  end

  describe '#event_created' do
    let!(:account) { create(:account) }
    let!(:contact) { create(:contact, account: account) }
    let!(:deal) { create(:deal, contact: contact, account: account) }
    let(:event) { build(:event, account: account, deal: deal, contact: contact) }
    let(:webhook_payload) { JSON.parse(WebhookWorker.jobs[0]['args'][1]) }

    before do
      create(:webhook, account: account)
      account.webhooks.reload
    end

    it 'should delivery event created' do
      expect do
        event.save
      end.to change(WebhookWorker.jobs, :size).by(1)
      expect(webhook_payload['event']).to eq('event_created')
      expect(webhook_payload['data']['content']['body']).to eq('Hi Lorena')
    end
  end
end
