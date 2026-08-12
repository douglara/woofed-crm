# spec/jobs/apps/salesforce/backfill/download_job_spec.rb
require 'rails_helper'

RSpec.describe Apps::Salesforce::Backfill::DownloadJob do
  include_context 'with salesforce backfill jobs enqueued'

  let!(:salesforce) { create(:apps_salesforces, :connected) }
  let!(:sync_run) { create(:apps_salesforce_sync_runs, :running, app: salesforce) }
  let(:results_url) do
    'https://woofed-dev-ed.my.salesforce.com/services/data/v64.0/jobs/query/' \
      "#{sync_run.bulk_job_id}/results"
  end
  let(:csv) { "\"Id\",\"Name\"\n\"001Hn00001AbCdEIAV\",\"Acme Ltda\"\n" }

  describe '#perform' do
    context 'when more pages are waiting' do
      it 'stages the page, checkpoints the locator and asks for the next one' do
        stub_request(:get, results_url).with(query: hash_including({}))
                                       .to_return(status: 200, body: csv,
                                                  headers: { 'Sforce-Locator' => 'MTAwMDA' })

        expect { described_class.perform_now(sync_run.id) }.to have_enqueued_job(described_class)

        expect(sync_run.reload.locator).to eq('MTAwMDA')
        expect(sync_run).to be_running
        expect(Apps::Salesforce::SyncRecord.count).to eq(1)
      end

      it 'resumes from the checkpoint instead of downloading everything again' do
        sync_run.update!(locator: 'MTAwMDA')
        stub_request(:get, results_url).with(query: hash_including('locator' => 'MTAwMDA'))
                                       .to_return(status: 200, body: csv, headers: { 'Sforce-Locator' => 'null' })

        described_class.perform_now(sync_run.id)

        expect(a_request(:get, results_url).with(query: hash_including('locator' => 'MTAwMDA')))
          .to have_been_made
      end
    end

    context 'when the last page arrives' do
      it 'finishes the run' do
        stub_request(:get, results_url).with(query: hash_including({}))
                                       .to_return(status: 200, body: csv, headers: { 'Sforce-Locator' => 'null' })

        described_class.perform_now(sync_run.id)

        expect(sync_run.reload).to be_completed
        expect(sync_run.records_downloaded).to eq(1)
      end
    end

    context 'when the download fails' do
      it 'records the reason and stops' do
        stub_request(:get, results_url).with(query: hash_including({}))
                                       .to_return(status: 404, body: [{ message: 'Job not found' }].to_json)

        described_class.perform_now(sync_run.id)

        expect(sync_run.reload).to be_failed
        expect(sync_run.error).to eq('Job not found')
      end
    end

    context 'when the run is already finished or gone' do
      it 'does nothing, so a retry never stages the same page twice' do
        sync_run.complete!

        described_class.perform_now(sync_run.id)
        described_class.perform_now(0)

        expect(Apps::Salesforce::SyncRecord.count).to eq(0)
      end
    end
  end
end
