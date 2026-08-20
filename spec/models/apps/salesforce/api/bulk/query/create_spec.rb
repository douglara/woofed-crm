# spec/models/apps/salesforce/api/bulk/query/create_spec.rb
require 'rails_helper'

RSpec.describe Apps::Salesforce::Api::Bulk::Query::Create do
  let!(:salesforce) { create(:apps_salesforces, :connected) }
  let(:jobs_url) { 'https://woofed-dev-ed.my.salesforce.com/services/data/v64.0/jobs/query' }
  let(:soql) { 'SELECT Id, Name FROM Account' }
  let(:job_id) { '750Hn00000AbCdEIAV' }

  describe '.call' do
    context 'when salesforce accepts the job' do
      it 'submits the query and returns the job id to poll' do
        stub_request(:post, jobs_url).to_return(
          status: 200, body: { id: job_id, state: 'UploadComplete' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

        result = described_class.call(salesforce, soql)

        expect(a_request(:post, jobs_url).with(body: { operation: 'query', query: soql }.to_json)).to have_been_made
        expect(result[:ok]).to eq(job_id)
      end
    end

    context 'when deleted records are wanted' do
      it 'submits a queryAll job' do
        stub_request(:post, jobs_url).to_return(status: 200, body: { id: job_id }.to_json)

        described_class.call(salesforce, soql, include_deleted: true)

        expect(a_request(:post, jobs_url).with(body: { operation: 'queryAll', query: soql }.to_json))
          .to have_been_made
      end
    end

    context 'when salesforce refuses the job' do
      it 'reports the reason' do
        stub_request(:post, jobs_url).to_return(status: 400, body: [{ message: 'MALFORMED_QUERY' }].to_json)

        expect(described_class.call(salesforce, soql)[:error]).to eq('MALFORMED_QUERY')
      end
    end
  end
end
