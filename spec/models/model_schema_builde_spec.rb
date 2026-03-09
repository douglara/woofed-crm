require 'rails_helper'

RSpec.describe ModelSchemaBuilder do
  let!(:account) { create(:account) }

  describe '.build' do
    context 'when building schema for Deal' do
      let(:fields) { described_class.build(Deal) }
      let(:field_names) { fields.map { |f| f[:name] } }

      it 'includes Deal own attributes' do
        expect(field_names).to include('name')
        expect(field_names).to include('status')
        expect(field_names).to include('created_at')
      end

      it 'excludes account_id field' do
        expect(field_names).not_to include('account_id')
      end

      it 'excludes fields ending with _id from own attributes' do
        own_attrs_with_id = Deal.ransackable_attributes(nil).select { |a| a.end_with?('_id') && a != 'id' }
        own_attrs_with_id.each do |attr|
          expect(field_names).not_to include(attr)
        end
      end

      it 'returns correct field structure' do
        field = fields.find { |f| f[:name] == 'name' }
        expect(field).to include(:name, :label, :type)
        expect(field[:type]).to eq('text')
      end

      it 'maps enum fields as select type with options' do
        status_field = fields.find { |f| f[:name] == 'status' }
        expect(status_field[:type]).to eq('select')
        expect(status_field[:options]).to be_an(Array)
        option_values = status_field[:options].map { |o| o[:value] }
        expect(option_values).to include('open', 'won', 'lost')
      end

      it 'maps datetime fields as date type' do
        created_at_field = fields.find { |f| f[:name] == 'created_at' }
        expect(created_at_field[:type]).to eq('date')
      end

      it 'maps integer fields as number type' do
        amount_field = fields.find { |f| f[:name] == 'total_deal_products_amount_in_cents' }
        expect(amount_field[:type]).to eq('number')
      end

      it 'includes association nested fields' do
        expect(field_names).to include('contact_full_name')
        expect(field_names).to include('contact_email')
      end

      it 'includes association id fields as relation type and builds correct relation metadata' do
        contact_id_field = fields.find { |f| f[:name] == 'contact_id' }
        expect(contact_id_field[:type]).to eq('relation')
        expect(contact_id_field[:relation]).to include(:model, :modelName, :labelKey, :valueKey, :searchKey)
        expect(contact_id_field[:relation][:model]).to eq('Contact')
        expect(contact_id_field[:relation][:modelName]).to eq('contact')
        expect(contact_id_field[:relation][:labelKey]).to eq('full_name')
        expect(contact_id_field[:relation][:valueKey]).to eq('id')
      end

      it 'builds labels with association prefix for nested fields' do
        contact_field = fields.find { |f| f[:name] == 'contact_full_name' }
        expect(contact_field[:label]).to include(' - ')
      end

      it 'excludes deal_products from associations' do
        expect(field_names.none? { |n| n.start_with?('deal_products_') }).to be true
      end
    end

    context 'when model does not respond to ransackable_attributes' do
      it 'returns empty array' do
        non_ransackable = Class.new
        result = described_class.build(non_ransackable)
        expect(result).to eq([])
      end
    end
  end

  describe 'EXCLUDED_FIELDS' do
    it 'includes sensitive fields' do
      expect(described_class::EXCLUDED_FIELDS).to include('encrypted_password')
      expect(described_class::EXCLUDED_FIELDS).to include('reset_password_token')
      expect(described_class::EXCLUDED_FIELDS).to include('account_id')
    end
  end

  describe 'EXCLUDED_ASSOCIATIONS' do
    it 'includes internal associations' do
      expect(described_class::EXCLUDED_ASSOCIATIONS).to include('account')
      expect(described_class::EXCLUDED_ASSOCIATIONS).to include('accounts')
      expect(described_class::EXCLUDED_ASSOCIATIONS).to include('deal_products')
    end
  end

  describe 'nested associations' do
    let(:fields) { described_class.build(Deal) }
    let(:field_names) { fields.map { |f| f[:name] } }

    it 'includes fields from nested associations (depth 2)' do
      expect(field_names).to include('pipeline_name')
    end

    it 'does not recurse beyond depth limit' do
      # Ensure no extremely deep nesting (>3 levels of underscores in prefix)
      deeply_nested = field_names.select { |n| n.split('_').length > 8 }
      expect(deeply_nested).to be_empty
    end
  end
end
