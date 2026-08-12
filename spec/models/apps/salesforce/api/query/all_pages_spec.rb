# spec/models/apps/salesforce/api/query/all_pages_spec.rb
require 'rails_helper'

RSpec.describe Apps::Salesforce::Api::Query::AllPages do
  let!(:salesforce) { create(:apps_salesforces, :connected) }
  let(:instance_url) { 'https://woofed-dev-ed.my.salesforce.com' }
  let(:query_url) { "#{instance_url}/services/data/v64.0/query" }
  let(:soql) { 'SELECT Id, Name FROM Account' }

  def json(body)
    { status: 200, body: body.to_json, headers: { 'Content-Type' => 'application/json' } }
  end

  describe '.call' do
    context 'when the whole result fits in one page' do
      it 'returns the records salesforce sent' do
        stub_request(:get, query_url).with(query: { q: soql })
                                     .to_return(json('done' => true,
                                                     'records' => [{ 'Id' => '001', 'Name' => 'Acme' }]))

        result = described_class.call(salesforce, soql)

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

        result = described_class.call(salesforce, soql)

        expect(result[:ok]).to eq([{ 'Id' => '001' }, { 'Id' => '002' }])
      end

      it 'hands each page to the block instead of accumulating them' do
        stub_request(:get, "#{instance_url}#{next_records_url}")
          .to_return(json('done' => true, 'records' => [{ 'Id' => '002' }]))
        pages = []

        result = described_class.call(salesforce, soql) { |records| pages << records }

        expect(pages).to eq([[{ 'Id' => '001' }], [{ 'Id' => '002' }]])
        expect(result[:ok]).to be_empty
      end

      it 'stops and reports when a later page fails, rather than returning half the records' do
        stub_request(:get, "#{instance_url}#{next_records_url}")
          .to_return(status: 500, body: [{ message: 'Server error' }].to_json)

        expect(described_class.call(salesforce, soql)[:error]).to eq('Server error')
      end
    end

    context 'when deleted records are wanted' do
      it 'walks the queryAll pages' do
        query_all_url = "#{instance_url}/services/data/v64.0/queryAll"
        stub_request(:get, query_all_url).with(query: { q: soql })
                                         .to_return(json('done' => true,
                                                         'records' => [{ 'Id' => '001', 'IsDeleted' => true }]))

        result = described_class.call(salesforce, soql, include_deleted: true)

        expect(result[:ok]).to eq([{ 'Id' => '001', 'IsDeleted' => true }])
      end
    end

    context 'when the first page fails' do
      it 'reports the reason instead of paging' do
        stub_request(:get, query_url).with(query: { q: soql })
                                     .to_return(status: 400, body: [{ message: "No such column 'Foo'" }].to_json)

        expect(described_class.call(salesforce, soql)[:error]).to eq("No such column 'Foo'")
      end
    end
  end
end
