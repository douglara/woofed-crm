# spec/models/apps/salesforce/backfill/soql_spec.rb
require 'rails_helper'

RSpec.describe Apps::Salesforce::Backfill::Soql do
  let!(:salesforce) { create(:apps_salesforces) }
  let(:object_mapping) do
    build(:apps_salesforce_object_mappings, app: salesforce, field_mappings: [
            { 'salesforce_field' => 'Name', 'woofed_field' => 'name' },
            { 'salesforce_field' => 'Phone', 'woofed_field' => 'phone' }
          ])
  end

  describe '#call' do
    context 'when it is the initial load' do
      it 'asks for the mapped fields plus the ones the sync always needs' do
        query = described_class.new(object_mapping).call

        expect(query).to eq('SELECT Id, SystemModstamp, Name, Phone FROM Account ORDER BY SystemModstamp')
      end

      it 'carries the relationship fields the caller resolved from the describe' do
        query = described_class.new(object_mapping, extra_fields: %w[OwnerId]).call

        expect(query).to start_with('SELECT Id, SystemModstamp, OwnerId, Name, Phone FROM Account')
      end

      it 'never asks for the same field twice' do
        mapping = build(:apps_salesforce_object_mappings, app: salesforce, field_mappings: [
                          { 'salesforce_field' => 'Id', 'woofed_field' => 'name' }
                        ])

        expect(described_class.new(mapping, extra_fields: %w[Id]).call)
          .to eq('SELECT Id, SystemModstamp FROM Account ORDER BY SystemModstamp')
      end
    end

    context 'when it is a catch-up' do
      it 'asks only for what changed after the cursor' do
        cursor = Time.utc(2026, 8, 1, 14, 22, 31)

        query = described_class.new(object_mapping, cursor: cursor).call

        expect(query).to include('WHERE SystemModstamp > 2026-08-01T14:22:31Z')
      end
    end

    context 'when the user set a filter on the mapping' do
      it 'respects the slice of the org they asked for' do
        mapping = build(:apps_salesforce_object_mappings, app: salesforce,
                                                          options: { 'filter' => 'CreatedDate = LAST_N_YEARS:2' })

        expect(described_class.new(mapping).call).to include('WHERE CreatedDate = LAST_N_YEARS:2')
      end

      it 'combines it with the cursor when both apply' do
        mapping = build(:apps_salesforce_object_mappings, app: salesforce,
                                                          options: { 'filter' => 'CreatedDate = LAST_N_YEARS:2' })

        query = described_class.new(mapping, cursor: Time.utc(2026, 8, 1)).call

        expect(query).to include('WHERE SystemModstamp > 2026-08-01T00:00:00Z AND CreatedDate = LAST_N_YEARS:2')
      end
    end
  end

  describe '#count' do
    it 'asks how big the object is, so the caller can pick a strategy' do
      expect(described_class.new(object_mapping).count).to eq('SELECT COUNT() FROM Account')
    end

    it 'counts only the slice a catch-up would download' do
      expect(described_class.new(object_mapping, cursor: Time.utc(2026, 8, 1)).count)
        .to eq('SELECT COUNT() FROM Account WHERE SystemModstamp > 2026-08-01T00:00:00Z')
    end
  end
end
