# spec/models/apps/salesforce/api_client/query_spec.rb
require 'rails_helper'

RSpec.describe Apps::Salesforce::ApiClient::Query do
  let!(:salesforce) { create(:apps_salesforces, :connected) }
  let(:client) { Apps::Salesforce::ApiClient.new(salesforce) }
  let(:instance_url) { 'https://woofed-dev-ed.my.salesforce.com' }
  let(:query_url) { "#{instance_url}/services/data/v64.0/query" }
  let(:soql) { 'SELECT Id, Name FROM Account' }

  def json(body)
    { status: 200, body: body.to_json, headers: { 'Content-Type' => 'application/json' } }
  end

  describe '#query' do
    context 'when the whole result fits in one page' do
      it 'returns the records salesforce sent' do
        stub_request(:get, query_url).with(query: { q: soql })
                                     .to_return(json('done' => true,
                                                     'records' => [{ 'Id' => '001', 'Name' => 'Acme' }]))

        result = client.query(soql)

        expect(result[:ok]).to eq([{ 'Id' => '001', 'Name' => 'Acme' }])
      end
    end

    context 'when salesforce splits the result across pages' do
      let(:next_records_url) { '/services/data/v64.0/query/01g5g00000XXXX-2000' }

      before do
        stub_request(:get, query_url).with(query: { q: soql })
                                     .to_return(json('done' => false,
                                                     'nextRecordsUrl' => next_records_url,
                                                     'records' => [{ 'Id' => '001' }]))
      end

      it 'follows the pages to the end' do
        stub_request(:get, "#{instance_url}#{next_records_url}")
          .to_return(json('done' => true, 'records' => [{ 'Id' => '002' }]))

        result = client.query(soql)

        expect(result[:ok]).to eq([{ 'Id' => '001' }, { 'Id' => '002' }])
      end

      it 'hands each page to the block instead of accumulating them' do
        stub_request(:get, "#{instance_url}#{next_records_url}")
          .to_return(json('done' => true, 'records' => [{ 'Id' => '002' }]))
        pages = []

        result = client.query(soql) { |records| pages << records }

        expect(pages).to eq([[{ 'Id' => '001' }], [{ 'Id' => '002' }]])
        expect(result[:ok]).to be_empty
      end

      it 'stops and reports when a later page fails, rather than returning half the records' do
        stub_request(:get, "#{instance_url}#{next_records_url}")
          .to_return(status: 500, body: [{ message: 'Server error' }].to_json)

        result = client.query(soql)

        expect(result[:error]).to eq('Server error')
      end
    end

    context 'when deleted records are wanted' do
      it 'asks queryAll, the only endpoint that still returns them' do
        query_all_url = "#{instance_url}/services/data/v64.0/queryAll"
        stub_request(:get, query_all_url).with(query: { q: soql })
                                         .to_return(json('done' => true,
                                                         'records' => [{ 'Id' => '001', 'IsDeleted' => true }]))

        result = client.query(soql, include_deleted: true)

        expect(result[:ok]).to eq([{ 'Id' => '001', 'IsDeleted' => true }])
      end
    end

    context 'when salesforce refuses the query' do
      it 'reports the reason instead of paging' do
        stub_request(:get, query_url).with(query: { q: soql })
                                     .to_return(status: 400,
                                                body: [{ message: "No such column 'Foo'" }].to_json)

        result = client.query(soql)

        expect(result[:error]).to eq("No such column 'Foo'")
      end
    end
  end
end
