# == Schema Information
#
# Table name: apps_salesforce_record_mappings
#
#  id                         :bigint           not null, primary key
#  deleted_at                 :datetime
#  last_synced_at             :datetime
#  recordable_type            :string           not null
#  salesforce_object          :string           not null
#  salesforce_system_modstamp :datetime
#  sync_error                 :text
#  sync_status                :string           default("pending"), not null
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  app_id                     :bigint           not null
#  recordable_id              :bigint           not null
#  salesforce_id              :string           not null
#
# Indexes
#
#  index_apps_salesforce_record_mappings_on_app_id        (app_id)
#  index_apps_salesforce_record_mappings_on_recordable    (recordable_type,recordable_id)
#  index_salesforce_record_mappings_on_app_object_and_id  (app_id,salesforce_object,salesforce_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (app_id => apps_salesforces.id)
#
# spec/models/apps/salesforce/record_mapping_spec.rb
require 'rails_helper'

RSpec.describe Apps::Salesforce::RecordMapping do
  let!(:salesforce) { create(:apps_salesforces) }

  describe 'validations' do
    context 'validates salesforce_id' do
      context 'valid' do
        it do
          mapping = build(:apps_salesforce_record_mappings, app: salesforce)

          expect(mapping).to be_valid
        end
        it 'when the same id belongs to a different salesforce object' do
          create(:apps_salesforce_record_mappings, app: salesforce, salesforce_object: 'Account',
                                                   salesforce_id: '001Hn00001AbCdEIAV')
          mapping = build(:apps_salesforce_record_mappings, :contact, app: salesforce,
                                                                     salesforce_id: '001Hn00001AbCdEIAV')

          expect(mapping).to be_valid
        end
      end
      context 'invalid' do
        it 'when the record is already mapped, which is what stops duplicates' do
          create(:apps_salesforce_record_mappings, app: salesforce)
          mapping = build(:apps_salesforce_record_mappings, app: salesforce)

          expect(mapping).to be_invalid
          expect(mapping.errors[:salesforce_id]).to include('has already been taken')
        end
        it 'when the 15 character form of an already mapped record arrives' do
          create(:apps_salesforce_record_mappings, app: salesforce, salesforce_id: '001Hn00001AbCdEIAV')
          mapping = build(:apps_salesforce_record_mappings, app: salesforce, salesforce_id: '001Hn00001AbCdE')

          expect(mapping).to be_invalid
        end
      end
    end
  end

  describe 'salesforce_id normalisation' do
    it 'stores the 18 character form so both forms find the same row' do
      mapping = create(:apps_salesforce_record_mappings, app: salesforce, salesforce_id: '001Hn00001AbCdE')

      expect(mapping.salesforce_id).to eq('001Hn00001AbCdEIAV')
      expect(described_class.find_by(salesforce_id: '001Hn00001AbCdE')).to eq(mapping)
    end
  end

  describe '#outdated?' do
    it 'is outdated only when salesforce reports a newer modification' do
      mapping = build(:apps_salesforce_record_mappings, salesforce_system_modstamp: '2026-08-01T14:22:31Z')

      expect(mapping).to be_outdated('2026-08-02T09:00:00Z')
      expect(mapping).not_to be_outdated('2026-08-01T14:22:31Z')
      expect(mapping).not_to be_outdated('2026-07-30T10:00:00Z')
    end

    it 'is outdated when either side has no modification stamp to compare' do
      expect(build(:apps_salesforce_record_mappings, salesforce_system_modstamp: nil))
        .to be_outdated('2026-08-02T09:00:00Z')
      expect(build(:apps_salesforce_record_mappings)).to be_outdated(nil)
    end
  end

  describe '#tombstone!' do
    it 'marks the salesforce record as gone while the woofed record survives' do
      mapping = create(:apps_salesforce_record_mappings, app: salesforce)
      company = mapping.recordable

      mapping.tombstone!

      expect(mapping.reload).to be_deleted
      expect(described_class.active).to be_empty
      expect(Company.find_by(id: company.id)).to be_present
    end
  end
end
