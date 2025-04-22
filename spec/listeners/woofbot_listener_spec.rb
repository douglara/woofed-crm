# frozen_string_literal: true

require 'rails_helper'
require 'sidekiq/testing'

describe WoofbotListener do
  # include ActiveJob::TestHelper
  describe '#event_created' do
    let!(:account) { create(:account) }
    let!(:apps_ai_assistent) { create(:apps_ai_assistent, account:, auto_reply: true) }
    let!(:contact) { create(:contact, account: account) }
    let!(:deal) { create(:deal, contact: contact, account: account) }
    let(:event) { build(:event, account: account, deal: deal, contact: contact) }
    let(:jobs) do
      Accounts::Contacts::Events::WoofbotWorker.jobs
    end

    it 'should delivery event created' do
      expect do
        event.save
      end.to change(jobs, :size).by(1)
    end
  end
end
