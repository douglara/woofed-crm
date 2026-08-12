# spec/jobs/apps/salesforce/backfill/object_job_spec.rb
require 'rails_helper'

RSpec.describe Apps::Salesforce::Backfill::ObjectJob do
  include_context 'with salesforce backfill jobs enqueued'

  let!(:salesforce) { create(:apps_salesforces, :connected) }
  let!(:object_mapping) { create(:apps_salesforce_object_mappings, app: salesforce) }
  let!(:sync_run) { create(:apps_salesforce_sync_runs, app: salesforce, salesforce_object: 'Account') }
  let(:instance_url) { 'https://woofed-dev-ed.my.salesforce.com' }
  let(:query_url) { "#{instance_url}/services/data/v64.0/query" }
  let(:describe_url) { "#{instance_url}/services/data/v64.0/sobjects/Account/describe" }
  let(:jobs_url) { "#{instance_url}/services/data/v64.0/jobs/query" }

  def stub_describe
    stub_request(:get, describe_url).to_return(
      status: 200, body: { 'fields' => [{ 'name' => 'OwnerId', 'type' => 'reference' }] }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
  end

  def stub_count(total)
    stub_request(:get, query_url).with(query: hash_including('q' => /COUNT/))
                                 .to_return(status: 200, body: { 'totalSize' => total }.to_json,
                                            headers: { 'Content-Type' => 'application/json' })
  end

  before { stub_describe }

  describe 'concurrency' do
    it 'keys on the run, so the same download never runs twice at once' do
      expect(described_class.new(sync_run.id).good_job_concurrency_key)
        .to eq("Apps::Salesforce::Backfill::ObjectJob-#{sync_run.id}")
    end
  end

  describe '#perform' do
    context 'when the object is small enough for a rest query' do
      it 'downloads it straight away and stages what it got' do
        stub_count(2)
        stub_request(:get, query_url).with(query: hash_including('q' => /SELECT Id/))
                                     .to_return(status: 200,
                                                body: { 'done' => true,
                                                        'records' => [{ 'Id' => '001Hn00001AbCdEIAV',
                                                                        'Name' => 'Acme' }] }.to_json,
                                                headers: { 'Content-Type' => 'application/json' })

        described_class.perform_now(sync_run.id)

        expect(sync_run.reload).to be_completed
        expect(sync_run.records_downloaded).to eq(1)
        expect(Apps::Salesforce::SyncRecord.count).to eq(1)
      end

      it 'stamps the cursor at submission, so an edit made during the run is not skipped' do
        stub_count(0)
        stub_request(:get, query_url).with(query: hash_including('q' => /SELECT Id/))
                                     .to_return(status: 200, body: { 'done' => true, 'records' => [] }.to_json)

        freeze_time do
          described_class.perform_now(sync_run.id)

          expect(sync_run.reload.cursor).to eq(Time.current)
        end
      end

      it 'records why it stopped when salesforce refuses the query' do
        stub_count(2)
        stub_request(:get, query_url).with(query: hash_including('q' => /SELECT Id/))
                                     .to_return(status: 400, body: [{ message: "No such column 'Foo'" }].to_json)

        described_class.perform_now(sync_run.id)

        expect(sync_run.reload).to be_failed
        expect(sync_run.error).to eq("No such column 'Foo'")
      end
    end

    context 'when the object is large' do
      it 'submits a bulk job and stores its id before polling it' do
        stub_count(described_class::BULK_THRESHOLD)
        stub_request(:post, jobs_url).to_return(status: 200, body: { id: '750Hn00000AbCdEIAV' }.to_json,
                                                headers: { 'Content-Type' => 'application/json' })

        expect { described_class.perform_now(sync_run.id) }
          .to have_enqueued_job(Apps::Salesforce::Backfill::PollJob)

        expect(sync_run.reload.bulk_job_id).to eq('750Hn00000AbCdEIAV')
        expect(sync_run).to be_running
      end

      it 'fails the run when salesforce refuses the job' do
        stub_count(described_class::BULK_THRESHOLD)
        stub_request(:post, jobs_url).to_return(status: 400, body: [{ message: 'MALFORMED_QUERY' }].to_json)

        described_class.perform_now(sync_run.id)

        expect(sync_run.reload).to be_failed
        expect(sync_run.error).to eq('MALFORMED_QUERY')
      end
    end

    context 'when the org cannot even be counted' do
      it 'fails the run rather than guessing a strategy' do
        stub_request(:get, query_url).with(query: hash_including('q' => /COUNT/))
                                     .to_return(status: 400, body: [{ message: 'Nope' }].to_json)

        described_class.perform_now(sync_run.id)

        expect(sync_run.reload).to be_failed
      end
    end

    context 'when the mapping was removed after the run was queued' do
      it 'fails the run instead of downloading with no instructions' do
        object_mapping.destroy

        described_class.perform_now(sync_run.id)

        expect(sync_run.reload).to be_failed
        expect(sync_run.error).to eq(I18n.t('apps.salesforce.backfill.mapping_missing'))
      end
    end

    context 'when the run is already finished or gone' do
      it 'does nothing, so a retry never downloads twice' do
        sync_run.complete!

        described_class.perform_now(sync_run.id)
        described_class.perform_now(0)

        expect(a_request(:get, query_url)).not_to have_been_made
      end
    end

    context 'when it is a catch-up' do
      it 'asks only for what changed since the last finished run' do
        create(:apps_salesforce_sync_runs, app: salesforce, salesforce_object: 'Account',
                                           status: 'completed', cursor: Time.utc(2026, 8, 1, 12))
        delta_run = create(:apps_salesforce_sync_runs, :delta, app: salesforce, salesforce_object: 'Account')
        stub_count(1)
        stub_request(:get, query_url).with(query: hash_including('q' => /SELECT Id/))
                                     .to_return(status: 200, body: { 'done' => true, 'records' => [] }.to_json)

        described_class.perform_now(delta_run.id)

        expect(a_request(:get, query_url)
          .with(query: hash_including('q' => /\ASELECT Id.*SystemModstamp > 2026-08-01T12:00:00Z/)))
          .to have_been_made
      end
    end
  end
end
