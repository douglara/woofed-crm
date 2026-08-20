# spec/jobs/apps/salesforce/delta/poll_job_spec.rb
require 'rails_helper'

RSpec.describe Apps::Salesforce::Delta::PollJob do
  include_context 'with salesforce backfill jobs enqueued'

  describe '#perform' do
    context 'when an org is connected with objects enabled' do
      let!(:salesforce) { create(:apps_salesforces, :connected) }

      it 'queues a catch-up per enabled object, so the query uses the cursor' do
        create(:apps_salesforce_object_mappings, app: salesforce, salesforce_object: 'Account')
        create(:apps_salesforce_object_mappings, :opportunity, app: salesforce)

        expect { described_class.perform_now }
          .to have_enqueued_job(Apps::Salesforce::Backfill::ObjectJob).twice

        expect(salesforce.sync_runs.pluck(:salesforce_object, :kind))
          .to contain_exactly(%w[Account delta], %w[Opportunity delta])
      end

      it 'skips an object whose previous tick is still running, so ticks do not pile up' do
        create(:apps_salesforce_object_mappings, app: salesforce, salesforce_object: 'Account')
        create(:apps_salesforce_sync_runs, :running, app: salesforce, salesforce_object: 'Account')

        described_class.perform_now

        expect(salesforce.sync_runs.count).to eq(1)
      end
    end

    context 'when no org was ever connected' do
      it 'does nothing, since every install runs this cron' do
        expect { described_class.perform_now }
          .not_to have_enqueued_job(Apps::Salesforce::Backfill::ObjectJob)

        expect(Apps::Salesforce::SyncRun.count).to eq(0)
      end
    end

    context 'when the credentials were saved but consent was never given' do
      let!(:salesforce) { create(:apps_salesforces) }

      it 'does nothing, since there is no token to query with' do
        create(:apps_salesforce_object_mappings, app: salesforce, salesforce_object: 'Account')

        described_class.perform_now

        expect(salesforce.sync_runs).to be_empty
      end
    end
  end
end
