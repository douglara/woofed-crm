# spec/jobs/apps/salesforce/backfill/poll_job_spec.rb
require 'rails_helper'

RSpec.describe Apps::Salesforce::Backfill::PollJob do
  include_context 'with salesforce backfill jobs enqueued'

  let!(:salesforce) { create(:apps_salesforces, :connected) }
  let!(:sync_run) { create(:apps_salesforce_sync_runs, :running, app: salesforce) }
  let(:job_url) do
    "https://woofed-dev-ed.my.salesforce.com/services/data/v64.0/jobs/query/#{sync_run.bulk_job_id}"
  end

  def stub_state(state)
    stub_request(:get, job_url).to_return(status: 200, body: { state: state }.to_json,
                                          headers: { 'Content-Type' => 'application/json' })
  end

  describe '#perform' do
    context 'when the job is still running' do
      it 'asks again later instead of holding a worker for an hour' do
        stub_state('InProgress')

        expect { described_class.perform_now(sync_run.id) }
          .to have_enqueued_job(described_class).with(sync_run.id, 1)
      end

      it 'waits longer on each attempt, since every poll costs an api call' do
        stub_state('InProgress')

        expect { described_class.perform_now(sync_run.id, 3) }
          .to have_enqueued_job(described_class).at(a_value_within(5.seconds).of(2.minutes.from_now))
      end

      it 'gives up on a job that never finishes' do
        stub_state('InProgress')

        described_class.perform_now(sync_run.id, described_class::MAX_ATTEMPTS)

        expect(sync_run.reload).to be_failed
        expect(sync_run.error).to eq(I18n.t('apps.salesforce.backfill.bulk_job_stuck'))
      end
    end

    context 'when the job finished' do
      it 'hands over to the download' do
        stub_state('JobComplete')

        expect { described_class.perform_now(sync_run.id) }
          .to have_enqueued_job(Apps::Salesforce::Backfill::DownloadJob).with(sync_run.id)
      end
    end

    context 'when salesforce gave up on the job' do
      it 'records the state it reported' do
        stub_state('Failed')

        described_class.perform_now(sync_run.id)

        expect(sync_run.reload).to be_failed
        expect(sync_run.error).to eq(I18n.t('apps.salesforce.backfill.bulk_job_failed', state: 'Failed'))
      end
    end

    context 'when the job cannot be reached' do
      it 'fails the run with the reason' do
        stub_request(:get, job_url).to_return(status: 404, body: [{ message: 'Job not found' }].to_json)

        described_class.perform_now(sync_run.id)

        expect(sync_run.reload).to be_failed
        expect(sync_run.error).to eq('Job not found')
      end
    end

    context 'when there is no bulk job to poll' do
      it 'does nothing' do
        run_without_job = create(:apps_salesforce_sync_runs, app: salesforce, salesforce_object: 'Contact')

        expect { described_class.perform_now(run_without_job.id) }.not_to raise_error
        expect { described_class.perform_now(0) }.not_to raise_error
      end
    end
  end
end
