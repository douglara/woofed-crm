# spec/models/apps/salesforce/api/bulk/query/state_spec.rb
require 'rails_helper'

RSpec.describe Apps::Salesforce::Api::Bulk::Query::State do
  let!(:salesforce) { create(:apps_salesforces, :connected) }
  let(:job_id) { '750Hn00000AbCdEIAV' }
  let(:job_url) { "https://woofed-dev-ed.my.salesforce.com/services/data/v64.0/jobs/query/#{job_id}" }

  describe '.call' do
    context 'when the job is still running' do
      it 'reports where it is, since salesforce never announces the end' do
        stub_request(:get, job_url).to_return(
          status: 200, body: { id: job_id, state: 'InProgress', numberRecordsProcessed: 12_000 }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

        expect(described_class.call(salesforce, job_id)[:ok]).to eq('InProgress')
      end
    end

    context 'when the job failed on the salesforce side' do
      it 'reports the failed state instead of waiting forever' do
        stub_request(:get, job_url).to_return(status: 200, body: { state: 'Failed' }.to_json)

        expect(described_class.call(salesforce, job_id)[:ok]).to eq('Failed')
      end
    end

    context 'when the job cannot be found' do
      it 'reports the reason' do
        stub_request(:get, job_url).to_return(status: 404, body: [{ message: 'Job not found' }].to_json)

        expect(described_class.call(salesforce, job_id)[:error]).to eq('Job not found')
      end
    end
  end
end
