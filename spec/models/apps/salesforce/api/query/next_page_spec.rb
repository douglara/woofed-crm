# spec/models/apps/salesforce/api/query/next_page_spec.rb
require 'rails_helper'

RSpec.describe Apps::Salesforce::Api::Query::NextPage do
  let!(:salesforce) { create(:apps_salesforces, :connected) }
  let(:instance_url) { 'https://woofed-dev-ed.my.salesforce.com' }
  let(:next_records_url) { '/services/data/v64.0/query/01g5g00000XXXX-2000' }

  describe '.call' do
    it 'follows the cursor as given, without repeating the query' do
      stub_request(:get, "#{instance_url}#{next_records_url}").to_return(
        status: 200, body: { 'done' => true, 'records' => [{ 'Id' => '002' }] }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

      result = described_class.call(salesforce, next_records_url)

      expect(a_request(:get, "#{instance_url}#{next_records_url}").with(query: {})).to have_been_made
      expect(result[:ok]['records']).to eq([{ 'Id' => '002' }])
    end

    it 'reports a cursor salesforce no longer recognises' do
      stub_request(:get, "#{instance_url}#{next_records_url}")
        .to_return(status: 400, body: [{ message: 'Invalid query locator' }].to_json)

      expect(described_class.call(salesforce, next_records_url)[:error]).to eq('Invalid query locator')
    end
  end
end
