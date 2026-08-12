# spec/models/apps/salesforce/api/query/page_spec.rb
require 'rails_helper'

RSpec.describe Apps::Salesforce::Api::Query::Page do
  let!(:salesforce) { create(:apps_salesforces, :connected) }
  let(:instance_url) { 'https://woofed-dev-ed.my.salesforce.com' }
  let(:soql) { 'SELECT Id, Name FROM Account' }

  describe '.call' do
    context 'when only live records are wanted' do
      it 'sends the query and returns the first page' do
        query_url = "#{instance_url}/services/data/v64.0/query"
        stub_request(:get, query_url).with(query: { q: soql }).to_return(
          status: 200,
          body: { 'done' => true, 'records' => [{ 'Id' => '001', 'Name' => 'Acme' }] }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

        result = described_class.call(salesforce, soql)

        expect(result[:ok]['records']).to eq([{ 'Id' => '001', 'Name' => 'Acme' }])
      end
    end

    context 'when deleted records are wanted' do
      it 'asks queryAll, the only endpoint that still returns them' do
        query_all_url = "#{instance_url}/services/data/v64.0/queryAll"
        stub_request(:get, query_all_url).with(query: { q: soql }).to_return(
          status: 200,
          body: { 'done' => true, 'records' => [{ 'Id' => '001', 'IsDeleted' => true }] }.to_json
        )

        result = described_class.call(salesforce, soql, include_deleted: true)

        expect(result[:ok]['records']).to eq([{ 'Id' => '001', 'IsDeleted' => true }])
      end
    end

    context 'when salesforce refuses the query' do
      it 'reports the reason' do
        query_url = "#{instance_url}/services/data/v64.0/query"
        stub_request(:get, query_url).with(query: { q: soql })
                                     .to_return(status: 400, body: [{ message: "No such column 'Foo'" }].to_json)

        expect(described_class.call(salesforce, soql)[:error]).to eq("No such column 'Foo'")
      end
    end
  end
end
