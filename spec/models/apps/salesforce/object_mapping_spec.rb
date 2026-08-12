# == Schema Information
#
# Table name: apps_salesforce_object_mappings
#
#  id                :bigint           not null, primary key
#  enabled           :boolean          default(FALSE), not null
#  field_mappings    :jsonb            not null
#  options           :jsonb            not null
#  salesforce_object :string           not null
#  woofed_model      :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  app_id            :bigint           not null
#
# Indexes
#
#  index_apps_salesforce_object_mappings_on_app_id     (app_id)
#  index_salesforce_object_mappings_on_app_and_object  (app_id,salesforce_object) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (app_id => apps_salesforces.id)
#
# spec/models/apps/salesforce/object_mapping_spec.rb
require 'rails_helper'

RSpec.describe Apps::Salesforce::ObjectMapping do
  let!(:salesforce) { create(:apps_salesforces) }

  describe 'validations' do
    context 'validates salesforce_object' do
      context 'valid' do
        it do
          mapping = build(:apps_salesforce_object_mappings, app: salesforce)

          expect(mapping).to be_valid
        end
      end
      context 'invalid' do
        it 'when salesforce_object is blank' do
          mapping = build(:apps_salesforce_object_mappings, app: salesforce, salesforce_object: '')

          expect(mapping).to be_invalid
          expect(mapping.errors[:salesforce_object]).to include("can't be blank")
        end
        it 'when the object is already mapped, so the transform can never have two rules' do
          create(:apps_salesforce_object_mappings, app: salesforce, salesforce_object: 'Account')
          mapping = build(:apps_salesforce_object_mappings, app: salesforce, salesforce_object: 'Account')

          expect(mapping).to be_invalid
          expect(mapping.errors[:salesforce_object]).to include('has already been taken')
        end
      end
    end
    context 'validates woofed_model' do
      context 'valid' do
        it do
          mapping = build(:apps_salesforce_object_mappings, app: salesforce, woofed_model: 'Contact')

          expect(mapping).to be_valid
        end
      end
      context 'invalid' do
        it 'when the target model is not one the sync can write to' do
          mapping = build(:apps_salesforce_object_mappings, app: salesforce, woofed_model: 'User')

          expect(mapping).to be_invalid
          expect(mapping.errors[:woofed_model]).to include('is not included in the list')
        end
      end
    end
  end

  describe '.enabled' do
    it 'returns only the objects the user turned on, since nothing syncs by default' do
      enabled = create(:apps_salesforce_object_mappings, app: salesforce)
      create(:apps_salesforce_object_mappings, :disabled, :opportunity, app: salesforce)

      expect(described_class.enabled).to eq([enabled])
    end
  end

  describe '#salesforce_fields' do
    it 'lists the fields a SOQL select has to ask for, without repeating any' do
      mapping = build(:apps_salesforce_object_mappings, app: salesforce, field_mappings: [
                        { 'salesforce_field' => 'Name', 'woofed_field' => 'name' },
                        { 'salesforce_field' => 'Phone', 'woofed_field' => 'phone' },
                        { 'salesforce_field' => 'Phone', 'woofed_field' => 'mobile' },
                        { 'salesforce_field' => '', 'woofed_field' => 'ignored' }
                      ])

      expect(mapping.salesforce_fields).to eq(%w[Name Phone])
    end
  end

  describe '#woofed_field_for' do
    it 'answers where a salesforce field lands, and nothing for an unmapped one' do
      mapping = build(:apps_salesforce_object_mappings, app: salesforce)

      expect(mapping.woofed_field_for('Name')).to eq('name')
      expect(mapping.woofed_field_for('Industria__c')).to be_nil
    end
  end
end
