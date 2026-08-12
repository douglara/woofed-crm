# spec/models/apps/salesforce/load/record_spec.rb
require 'rails_helper'

RSpec.describe Apps::Salesforce::Load::Record do
  let!(:account) { create(:account) }
  let!(:salesforce) { create(:apps_salesforces) }
  let!(:object_mapping) do
    create(:apps_salesforce_object_mappings, app: salesforce, field_mappings: [
             { 'salesforce_field' => 'Name', 'woofed_field' => 'name', 'kind' => 'attribute' },
             { 'salesforce_field' => 'Website', 'woofed_field' => 'email', 'kind' => 'attribute' },
             { 'salesforce_field' => 'Industria__c', 'woofed_field' => 'industria',
               'kind' => 'custom_attribute' }
           ])
  end
  let(:payload) do
    {
      'Id' => '001Hn00001AbCdEIAV',
      'Name' => 'Acme Ltda',
      'Website' => 'contato@acme.com',
      'Industria__c' => 'Varejo',
      'SystemModstamp' => '2026-08-01T14:22:31.000Z'
    }
  end

  def stage(attributes = {})
    create(:apps_salesforce_sync_records, { app: salesforce, payload: payload }.merge(attributes))
  end

  describe '#call' do
    context 'when the record is new to woofed' do
      it 'creates it from the mapping and records which salesforce record it is' do
        sync_record = stage

        described_class.new(sync_record).call

        company = Company.find_by(name: 'Acme Ltda')
        expect(company).to have_attributes(email: 'contato@acme.com')
        expect(company.custom_attributes).to include('industria' => 'Varejo')
        expect(company.additional_attributes).to include('salesforce_id' => '001Hn00001AbCdEIAV')
        expect(sync_record.reload).to be_processed
      end

      it 'maps it, so the next sync updates instead of creating a second one' do
        sync_record = stage

        described_class.new(sync_record).call

        mapping = Apps::Salesforce::RecordMapping.last
        expect(mapping).to have_attributes(
          salesforce_object: 'Account',
          salesforce_id: '001Hn00001AbCdEIAV',
          recordable: Company.last,
          sync_status: 'synced'
        )
        expect(mapping.salesforce_system_modstamp).to eq(Time.utc(2026, 8, 1, 14, 22, 31))
      end
    end

    context 'when the record was imported before' do
      it 'updates the woofed record it owns' do
        company = create(:company, name: 'Old name')
        create(:apps_salesforce_record_mappings, app: salesforce, recordable: company,
                                                 salesforce_id: '001Hn00001AbCdEIAV',
                                                 salesforce_system_modstamp: '2026-07-01T10:00:00Z')

        expect { described_class.new(stage).call }.not_to change(Company, :count)
        expect(company.reload.name).to eq('Acme Ltda')
      end

      it 'does nothing when salesforce reports no change since the last sync' do
        company = create(:company, name: 'Old name')
        create(:apps_salesforce_record_mappings, app: salesforce, recordable: company,
                                                 salesforce_id: '001Hn00001AbCdEIAV',
                                                 salesforce_system_modstamp: '2026-08-01T14:22:31Z')
        sync_record = stage

        described_class.new(sync_record).call

        expect(company.reload.name).to eq('Old name')
        expect(sync_record.reload).to be_processed
      end
    end

    context 'when the crm already knows the record under another origin' do
      it 'adopts it instead of duplicating the company' do
        company = create(:company, email: 'contato@acme.com', name: 'Acme')

        expect { described_class.new(stage).call }.not_to change(Company, :count)
        expect(company.reload.name).to eq('Acme Ltda')
        expect(Apps::Salesforce::RecordMapping.last.recordable).to eq(company)
      end
    end

    context 'when the value belongs to a different woofed record' do
      it 'sets the row aside for a human instead of failing on the unique index' do
        create(:company, email: 'contato@acme.com')
        other = create(:company, name: 'Outra')
        create(:apps_salesforce_record_mappings, app: salesforce, recordable: other,
                                                 salesforce_id: '001Hn00001AbCdEIAV')
        sync_record = stage

        described_class.new(sync_record).call

        expect(sync_record.reload).to be_conflict
        expect(sync_record.error).to include('contato@acme.com')
        expect(other.reload.name).to eq('Outra')
      end
    end

    context 'when the record cannot be saved' do
      it 'keeps the reason on the staged row rather than losing it' do
        sync_record = stage(payload: payload.merge('Name' => ''))

        described_class.new(sync_record).call

        expect(sync_record.reload).to be_failed
        expect(sync_record.error).to include("Name can't be blank")
      end
    end

    context 'when the mapping was removed after the row was staged' do
      it 'fails the row, since there is no longer any way to interpret it' do
        sync_record = stage
        object_mapping.destroy

        described_class.new(sync_record).call

        expect(sync_record.reload).to be_failed
        expect(sync_record.error).to eq(I18n.t('apps.salesforce.backfill.mapping_missing'))
      end
    end

    context 'when other integrations already wrote to the jsonb columns' do
      it 'merges rather than replacing what is there' do
        company = create(:company, email: 'contato@acme.com',
                                   custom_attributes: { 'porte' => 'Médio' },
                                   additional_attributes: { 'chatwoot_id' => '9' })

        described_class.new(stage).call

        expect(company.reload.custom_attributes).to include('porte' => 'Médio', 'industria' => 'Varejo')
        expect(company.additional_attributes).to include('chatwoot_id' => '9',
                                                         'salesforce_id' => '001Hn00001AbCdEIAV')
      end
    end
  end
end
