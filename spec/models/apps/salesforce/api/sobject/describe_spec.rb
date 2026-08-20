# spec/models/apps/salesforce/api/sobject/describe_spec.rb
require 'rails_helper'

RSpec.describe Apps::Salesforce::Api::Sobject::Describe do
  let!(:salesforce) { create(:apps_salesforces, :connected) }
  let(:describe_url) do
    'https://woofed-dev-ed.my.salesforce.com/services/data/v64.0/sobjects/Account/describe'
  end
  let(:payload) do
    {
      'name' => 'Account',
      'fields' => [
        { 'name' => 'Name', 'label' => 'Account Name', 'type' => 'string' },
        { 'name' => 'Industria__c', 'label' => 'Indústria', 'type' => 'picklist' }
      ]
    }
  end

  # The test environment uses a null cache store, so caching is exercised against
  # a real store instead of being assumed.
  before { allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new) }

  describe '.call' do
    context 'when the org answers' do
      it 'returns the field metadata the mapping screen builds its pickers from' do
        stub_request(:get, describe_url).to_return(
          status: 200, body: payload.to_json, headers: { 'Content-Type' => 'application/json' }
        )

        result = described_class.call(salesforce, 'Account')

        expect(result[:ok]['fields'].map { |field| field['name'] }).to eq(%w[Name Industria__c])
      end

      it 'asks the org once and serves the payload from the cache afterwards' do
        stub_request(:get, describe_url).to_return(status: 200, body: payload.to_json)

        described_class.call(salesforce, 'Account')
        second_result = described_class.call(salesforce, 'Account')

        expect(a_request(:get, describe_url)).to have_been_made.once
        expect(second_result[:ok]['name']).to eq('Account')
      end
    end

    context 'when the org refuses' do
      it 'reports the failure without caching it' do
        stub_request(:get, describe_url).to_return(
          status: 400, body: [{ message: 'The requested resource does not exist' }].to_json
        )

        result = described_class.call(salesforce, 'Account')
        described_class.call(salesforce, 'Account')

        expect(result[:error]).to eq('The requested resource does not exist')
        expect(a_request(:get, describe_url)).to have_been_made.twice
      end
    end
  end
end
