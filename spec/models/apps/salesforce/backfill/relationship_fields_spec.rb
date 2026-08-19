# spec/models/apps/salesforce/backfill/relationship_fields_spec.rb
require 'rails_helper'

RSpec.describe Apps::Salesforce::Backfill::RelationshipFields do
  let!(:salesforce) { create(:apps_salesforces, :connected) }
  let(:describe_url) do
    "https://woofed-dev-ed.my.salesforce.com/services/data/v64.0/sobjects/#{salesforce_object}/describe"
  end
  let(:salesforce_object) { 'Account' }

  def stub_describe(fields)
    stub_request(:get, describe_url).to_return(
      status: 200, body: { 'fields' => fields }.to_json, headers: { 'Content-Type' => 'application/json' }
    )
  end

  describe '.call' do
    context 'when the object has lookups' do
      it 'reads them off the describe, so custom objects work without a hardcoded list' do
        stub_describe([
                        { 'name' => 'OwnerId', 'type' => 'reference' },
                        { 'name' => 'ParentId', 'type' => 'reference' },
                        { 'name' => 'Name', 'type' => 'string' }
                      ])
        mapping = build(:apps_salesforce_object_mappings, app: salesforce)

        expect(described_class.call(mapping)).to eq(%w[OwnerId ParentId])
      end
    end

    context 'when the object carries meaning beyond its links' do
      let(:salesforce_object) { 'Opportunity' }

      it 'adds the fields the loader needs to place a deal' do
        stub_describe([{ 'name' => 'AccountId', 'type' => 'reference' }])
        mapping = build(:apps_salesforce_object_mappings, :opportunity, app: salesforce)

        expect(described_class.call(mapping)).to eq(%w[AccountId StageName IsWon IsClosed CloseDate])
      end
    end

    # A stage is usually a picklist and maps to no woofed column, so nothing else
    # in the query would ask for it.
    context 'when a custom object mapped onto deal reads its stage from its own field' do
      let(:salesforce_object) { 'Customer_Success__c' }

      def deal_mapping(options = {})
        build(:apps_salesforce_object_mappings, :opportunity, app: salesforce, options: options,
                                                              salesforce_object: salesforce_object)
      end

      it 'selects that field, so the payload the loader reads back carries the stage' do
        stub_describe([{ 'name' => 'AccountId', 'type' => 'reference' }])

        expect(described_class.call(deal_mapping('stage_field' => 'Status__c')))
          .to eq(%w[AccountId Status__c])
      end

      it 'asks for nothing extra when no field was configured' do
        stub_describe([{ 'name' => 'AccountId', 'type' => 'reference' }])

        expect(described_class.call(deal_mapping)).to eq(%w[AccountId])
      end
    end

    context 'when the mapping writes to a model that has no stage' do
      it 'ignores a stage field left over on it' do
        stub_describe([{ 'name' => 'OwnerId', 'type' => 'reference' }])
        mapping = build(:apps_salesforce_object_mappings, app: salesforce,
                                                          options: { 'stage_field' => 'Status__c' })

        expect(described_class.call(mapping)).to eq(%w[OwnerId])
      end
    end

    context 'when the org refuses the describe' do
      it 'still lets the query run, just without resolving relationships' do
        stub_request(:get, describe_url).to_return(status: 400, body: [{ message: 'Nope' }].to_json)
        mapping = build(:apps_salesforce_object_mappings, app: salesforce)

        expect(described_class.call(mapping)).to eq([])
      end
    end
  end
end
