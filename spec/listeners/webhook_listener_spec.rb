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
    let!(:webhook) { create(:webhook, account: account) }
    let!(:contact) { create(:contact, account: account) }
    let!(:deal) { create(:deal, contact:contact, account: account) }
    let(:event) { build(:event, account: account, deal: deal, contact: contact) }

    it 'adds system users' do
      expect {
        event.save
      }.to change(WebhookWorker.jobs, :size).by(1)
    end
  end
end
