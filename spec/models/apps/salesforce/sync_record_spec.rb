# spec/models/apps/salesforce/sync_record_spec.rb
require 'rails_helper'

RSpec.describe Apps::Salesforce::SyncRecord do
  let!(:salesforce) { create(:apps_salesforces) }

  describe 'validations' do
    context 'validates salesforce_id' do
      context 'valid' do
        it do
          sync_record = build(:apps_salesforce_sync_records, app: salesforce)

          expect(sync_record).to be_valid
        end
        it 'when the same record is staged twice, since a re-run must be able to stage it again' do
          create(:apps_salesforce_sync_records, app: salesforce)
          sync_record = build(:apps_salesforce_sync_records, app: salesforce)

          expect(sync_record).to be_valid
        end
      end
      context 'invalid' do
        it 'when salesforce_id is blank' do
          sync_record = build(:apps_salesforce_sync_records, app: salesforce, salesforce_id: '')

          expect(sync_record).to be_invalid
          expect(sync_record.errors[:salesforce_id]).to include("can't be blank")
        end
      end
    end
  end

  describe 'the staged payload' do
    it 'keeps the row exactly as salesforce sent it, so remapping needs no download' do
      sync_record = create(:apps_salesforce_sync_records, app: salesforce)

      expect(sync_record.reload.payload).to eq(
        'Id' => '001Hn00001AbCdEIAV', 'Name' => 'Acme Ltda', 'SystemModstamp' => '2026-08-01T14:22:31.000Z'
      )
    end

    it 'normalises the id so a staged row matches its record mapping' do
      sync_record = create(:apps_salesforce_sync_records, app: salesforce, salesforce_id: '001Hn00001AbCdE')

      expect(sync_record.salesforce_id).to eq('001Hn00001AbCdEIAV')
    end
  end

  describe '#mark_processed!' do
    it 'clears the previous error, since the row went through this time' do
      sync_record = create(:apps_salesforce_sync_records, app: salesforce, status: 'failed', error: 'Timeout')

      sync_record.mark_processed!

      expect(sync_record.reload).to be_processed
      expect(sync_record).to have_attributes(error: nil, processed_at: be_present)
    end
  end

  describe '#mark_failed!' do
    it 'keeps the reason so the row can be retried or inspected' do
      sync_record = create(:apps_salesforce_sync_records, app: salesforce)

      sync_record.mark_failed!('Phone could not be normalised')

      expect(sync_record.reload).to be_failed
      expect(sync_record.error).to eq('Phone could not be normalised')
    end
  end

  describe '#mark_conflict!' do
    it 'sets the row aside for a human instead of failing it silently' do
      sync_record = create(:apps_salesforce_sync_records, app: salesforce)

      sync_record.mark_conflict!('Email already belongs to contact #781')

      expect(sync_record.reload).to be_conflict
      expect(sync_record.error).to eq('Email already belongs to contact #781')
      expect(described_class.pending).to be_empty
    end
  end
end
