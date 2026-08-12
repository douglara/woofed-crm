# spec/models/apps/salesforce/bulk_query_spec.rb
require 'rails_helper'

RSpec.describe Apps::Salesforce::BulkQuery do
  let!(:salesforce) { create(:apps_salesforces, :connected) }
  let(:soql) { 'SELECT Id, Name FROM Account' }
  let(:bulk_query) { described_class.new(salesforce, soql) }
  let(:jobs_url) { 'https://woofed-dev-ed.my.salesforce.com/services/data/v64.0/jobs/query' }
  let(:job_id) { '750Hn00000AbCdEIAV' }

  describe '#create' do
    context 'when salesforce accepts the job' do
      it 'submits the query and returns the job id to poll' do
        stub_request(:post, jobs_url).to_return(
          status: 200, body: { id: job_id, state: 'UploadComplete' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

        result = bulk_query.create

        expect(a_request(:post, jobs_url).with(body: { operation: 'query', query: soql }.to_json)).to have_been_made
        expect(result[:ok]).to eq(job_id)
      end
    end

    context 'when deleted records are wanted' do
      it 'submits a queryAll job' do
        stub_request(:post, jobs_url).to_return(status: 200, body: { id: job_id }.to_json)

        described_class.new(salesforce, soql, include_deleted: true).create

        expect(a_request(:post, jobs_url).with(body: { operation: 'queryAll', query: soql }.to_json))
          .to have_been_made
      end
    end

    context 'when salesforce refuses the job' do
      it 'reports the reason' do
        stub_request(:post, jobs_url).to_return(
          status: 400, body: [{ message: 'MALFORMED_QUERY' }].to_json
        )

        expect(bulk_query.create[:error]).to eq('MALFORMED_QUERY')
      end
    end
  end

  describe '#state' do
    it 'reports where the job is, since salesforce never announces the end' do
      stub_request(:get, "#{jobs_url}/#{job_id}").to_return(
        status: 200, body: { id: job_id, state: 'InProgress', numberRecordsProcessed: 12_000 }.to_json
      )

      expect(bulk_query.state(job_id)[:ok]).to eq('InProgress')
    end

    it 'reports a job that failed on the salesforce side' do
      stub_request(:get, "#{jobs_url}/#{job_id}").to_return(status: 200, body: { state: 'Failed' }.to_json)

      expect(bulk_query.state(job_id)[:ok]).to eq('Failed')
    end
  end

  describe '#results' do
    let(:results_url) { "#{jobs_url}/#{job_id}/results" }
    let(:csv) { "\"Id\",\"Name\"\n\"001Hn00001AbCdEIAV\",\"Acme Ltda\"\n\"001Hn00001XyZwVIAX\",\"\"\n" }

    context 'when there are more records to download' do
      it 'returns the parsed rows and the locator to resume from' do
        stub_request(:get, results_url).with(query: { maxRecords: 10_000 })
                                       .to_return(status: 200, body: csv,
                                                  headers: { 'Sforce-Locator' => 'MTAwMDA' })

        result = bulk_query.results(job_id)

        expect(result[:ok][:records]).to eq(
          [{ 'Id' => '001Hn00001AbCdEIAV', 'Name' => 'Acme Ltda' },
           { 'Id' => '001Hn00001XyZwVIAX', 'Name' => '' }]
        )
        expect(result[:ok]).to include(locator: 'MTAwMDA', done: false)
      end

      it 'resumes from the locator it was given' do
        stub_request(:get, results_url).with(query: { maxRecords: 10_000, locator: 'MTAwMDA' })
                                       .to_return(status: 200, body: csv, headers: { 'Sforce-Locator' => 'null' })

        result = bulk_query.results(job_id, locator: 'MTAwMDA')

        expect(a_request(:get, results_url).with(query: { maxRecords: 10_000, locator: 'MTAwMDA' }))
          .to have_been_made
        expect(result[:ok]).to include(done: true, locator: nil)
      end
    end

    context 'when the download is over' do
      it 'reports it as done' do
        stub_request(:get, results_url).with(query: { maxRecords: 10_000 })
                                       .to_return(status: 200, body: csv, headers: { 'Sforce-Locator' => 'null' })

        expect(bulk_query.results(job_id)[:ok]).to include(done: true, locator: nil)
      end

      it 'handles a job that matched no records at all' do
        stub_request(:get, results_url).with(query: { maxRecords: 10_000 }).to_return(status: 200, body: '')

        expect(bulk_query.results(job_id)[:ok]).to include(records: [], done: true)
      end
    end

    context 'when the download fails' do
      it 'reports the reason' do
        stub_request(:get, results_url).with(query: { maxRecords: 10_000 })
                                       .to_return(status: 404, body: [{ message: 'Job not found' }].to_json)

        expect(bulk_query.results(job_id)[:error]).to eq('Job not found')
      end
    end
  end
end
