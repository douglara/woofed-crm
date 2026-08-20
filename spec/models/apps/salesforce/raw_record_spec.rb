# == Schema Information
#
# Table name: apps_salesforce_raw_records
#
#  id                :bigint           not null, primary key
#  error             :text
#  payload           :jsonb            not null
#  processed_at      :datetime
#  salesforce_object :string           not null
#  status            :string           default("pending"), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  app_id            :bigint           not null
#  salesforce_id     :string           not null
#  sync_run_id       :bigint
#
# Indexes
#
#  index_apps_salesforce_raw_records_on_app_id        (app_id)
#  index_apps_salesforce_raw_records_on_sync_run_id   (sync_run_id)
#  index_salesforce_raw_records_on_app_and_status     (app_id,status)
#  index_salesforce_raw_records_on_app_object_and_id  (app_id,salesforce_object,salesforce_id)
#
# Foreign Keys
#
#  fk_rails_...  (app_id => apps_salesforces.id)
#  fk_rails_...  (sync_run_id => apps_salesforce_sync_runs.id)
#
# spec/models/apps/salesforce/raw_record_spec.rb
require 'rails_helper'

RSpec.describe Apps::Salesforce::RawRecord do
  let!(:salesforce) { create(:apps_salesforces) }

  describe 'validations' do
    context 'validates salesforce_id' do
      context 'valid' do
        it do
          raw_record = build(:apps_salesforce_raw_records, app: salesforce)

          expect(raw_record).to be_valid
        end
        it 'when the same record is staged twice, since a re-run must be able to stage it again' do
          create(:apps_salesforce_raw_records, app: salesforce)
          raw_record = build(:apps_salesforce_raw_records, app: salesforce)

          expect(raw_record).to be_valid
        end
      end
      context 'invalid' do
        it 'when salesforce_id is blank' do
          raw_record = build(:apps_salesforce_raw_records, app: salesforce, salesforce_id: '')

          expect(raw_record).to be_invalid
          expect(raw_record.errors[:salesforce_id]).to include("can't be blank")
        end
      end
    end
  end

  describe 'the staged payload' do
    it 'keeps the row exactly as salesforce sent it, so remapping needs no download' do
      raw_record = create(:apps_salesforce_raw_records, app: salesforce)

      expect(raw_record.reload.payload).to eq(
        'Id' => '001Hn00001AbCdEIAV', 'Name' => 'Acme Ltda', 'SystemModstamp' => '2026-08-01T14:22:31.000Z'
      )
    end

    it 'normalises the id so a staged row matches its record link' do
      raw_record = create(:apps_salesforce_raw_records, app: salesforce, salesforce_id: '001Hn00001AbCdE')

      expect(raw_record.salesforce_id).to eq('001Hn00001AbCdEIAV')
    end
  end

  describe '#mark_processed!' do
    it 'clears the previous error, since the row went through this time' do
      raw_record = create(:apps_salesforce_raw_records, app: salesforce, status: 'failed', error: 'Timeout')

      raw_record.mark_processed!

      expect(raw_record.reload).to be_processed
      expect(raw_record).to have_attributes(error: nil, processed_at: be_present)
    end
  end

  describe '#mark_failed!' do
    it 'keeps the reason so the row can be retried or inspected' do
      raw_record = create(:apps_salesforce_raw_records, app: salesforce)

      raw_record.mark_failed!('Phone could not be normalised')

      expect(raw_record.reload).to be_failed
      expect(raw_record.error).to eq('Phone could not be normalised')
    end
  end

  describe '#mark_conflict!' do
    it 'sets the row aside for a human instead of failing it silently' do
      raw_record = create(:apps_salesforce_raw_records, app: salesforce)

      raw_record.mark_conflict!('Email already belongs to contact #781')

      expect(raw_record.reload).to be_conflict
      expect(raw_record.error).to eq('Email already belongs to contact #781')
      expect(described_class.pending).to be_empty
    end
  end
end
