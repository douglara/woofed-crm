# spec/models/apps/salesforce/api/bulk/query/results_spec.rb
require 'rails_helper'

RSpec.describe Apps::Salesforce::Api::Bulk::Query::Results do
  let!(:salesforce) { create(:apps_salesforces, :connected) }
  let(:job_id) { '750Hn00000AbCdEIAV' }
  let(:results_url) do
    "https://woofed-dev-ed.my.salesforce.com/services/data/v64.0/jobs/query/#{job_id}/results"
  end
  let(:csv) { "\"Id\",\"Name\"\n\"001Hn00001AbCdEIAV\",\"Acme Ltda\"\n\"001Hn00001XyZwVIAX\",\"\"\n" }

  describe '.call' do
    context 'when there are more records to download' do
      it 'returns the parsed rows and the locator to resume from' do
        stub_request(:get, results_url).with(query: { maxRecords: 10_000 })
                                       .to_return(status: 200, body: csv,
                                                  headers: { 'Sforce-Locator' => 'MTAwMDA' })

        result = described_class.call(salesforce, job_id)

        expect(result[:ok][:records]).to eq(
          [{ 'Id' => '001Hn00001AbCdEIAV', 'Name' => 'Acme Ltda' },
           { 'Id' => '001Hn00001XyZwVIAX', 'Name' => '' }]
        )
        expect(result[:ok]).to include(locator: 'MTAwMDA', done: false)
      end

      it 'resumes from the locator it was given' do
        stub_request(:get, results_url).with(query: { maxRecords: 10_000, locator: 'MTAwMDA' })
                                       .to_return(status: 200, body: csv, headers: { 'Sforce-Locator' => 'null' })

        result = described_class.call(salesforce, job_id, locator: 'MTAwMDA')

        expect(a_request(:get, results_url).with(query: { maxRecords: 10_000, locator: 'MTAwMDA' }))
          .to have_been_made
        expect(result[:ok]).to include(done: true, locator: nil)
      end
    end

    context 'when the download is over' do
      it 'reports it as done' do
        stub_request(:get, results_url).with(query: { maxRecords: 10_000 })
                                       .to_return(status: 200, body: csv, headers: { 'Sforce-Locator' => 'null' })

        expect(described_class.call(salesforce, job_id)[:ok]).to include(done: true, locator: nil)
      end

      it 'handles a job that matched no records at all' do
        stub_request(:get, results_url).with(query: { maxRecords: 10_000 }).to_return(status: 200, body: '')

        expect(described_class.call(salesforce, job_id)[:ok]).to include(records: [], done: true)
      end
    end

    context 'when the download fails' do
      it 'reports the reason' do
        stub_request(:get, results_url).with(query: { maxRecords: 10_000 })
                                       .to_return(status: 404, body: [{ message: 'Job not found' }].to_json)

        expect(described_class.call(salesforce, job_id)[:error]).to eq('Job not found')
      end
    end
  end
end
