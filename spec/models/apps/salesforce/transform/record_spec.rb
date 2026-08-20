# spec/models/apps/salesforce/transform/record_spec.rb
require 'rails_helper'

RSpec.describe Apps::Salesforce::Transform::Record do
  let!(:salesforce) { create(:apps_salesforces) }
  let(:payload) do
    {
      'Id' => '001Hn00001AbCdEIAV',
      'Name' => '  Acme Ltda ',
      'Phone' => '+55 11 3333-4444',
      'Industria__c' => 'Varejo'
    }
  end

  describe '#call' do
    context 'when every field converts' do
      it 'splits the row into attributes and custom attributes, following the mapping' do
        mapping = build(:apps_salesforce_object_mappings, app: salesforce, field_mappings: [
                          { 'salesforce_field' => 'Name', 'woofed_field' => 'name', 'kind' => 'attribute' },
                          { 'salesforce_field' => 'Phone', 'woofed_field' => 'phone', 'kind' => 'attribute' },
                          { 'salesforce_field' => 'Industria__c', 'woofed_field' => 'industria',
                            'kind' => 'custom_attribute' }
                        ])

        result = described_class.new(mapping, payload).call

        expect(result[:ok][:attributes]).to eq('name' => 'Acme Ltda', 'phone' => '+551133334444')
        expect(result[:ok][:custom_attributes]).to eq('industria' => 'Varejo')
        expect(result[:warnings]).to be_empty
      end

      it 'mirrors the salesforce id onto the record so it stays visible and searchable' do
        mapping = build(:apps_salesforce_object_mappings, app: salesforce)

        result = described_class.new(mapping, payload).call

        expect(result[:ok][:additional_attributes]).to include('salesforce_id' => '001Hn00001AbCdEIAV')
      end

      it 'normalises a 15 character id, so it matches its record link' do
        mapping = build(:apps_salesforce_object_mappings, app: salesforce)

        result = described_class.new(mapping, payload.merge('Id' => '001Hn00001AbCdE')).call

        expect(result[:ok][:additional_attributes]['salesforce_id']).to eq('001Hn00001AbCdEIAV')
      end
    end

    context 'when the mapping names a transform explicitly' do
      it 'uses it instead of the one inferred from the column' do
        mapping = build(:apps_salesforce_object_mappings, :opportunity, app: salesforce, field_mappings: [
                          { 'salesforce_field' => 'Amount', 'woofed_field' => 'total_amount_in_cents',
                            'kind' => 'attribute', 'transform' => 'currency_to_cents' }
                        ])

        result = described_class.new(mapping, 'Amount' => '1500.50').call

        expect(result[:ok][:attributes]).to eq('total_amount_in_cents' => 150_050)
      end
    end

    context 'when the mapping names no transform' do
      it 'infers it from the target column' do
        mapping = build(:apps_salesforce_object_mappings, :opportunity, app: salesforce, field_mappings: [
                          { 'salesforce_field' => 'Amount', 'woofed_field' => 'total_amount_in_cents',
                            'kind' => 'attribute' }
                        ])

        result = described_class.new(mapping, 'Amount' => '1500.50').call

        expect(result[:ok][:attributes]).to eq('total_amount_in_cents' => 150_050)
      end
    end

    context 'when a value cannot be converted' do
      it 'imports the record anyway, keeping the original and reporting why' do
        mapping = build(:apps_salesforce_object_mappings, app: salesforce, field_mappings: [
                          { 'salesforce_field' => 'Name', 'woofed_field' => 'name', 'kind' => 'attribute' },
                          { 'salesforce_field' => 'Phone', 'woofed_field' => 'phone', 'kind' => 'attribute' }
                        ])

        result = described_class.new(mapping, payload.merge('Phone' => '(11) 3333-4444')).call

        expect(result[:ok][:attributes]).to eq('name' => 'Acme Ltda')
        expect(result[:ok][:additional_attributes]).to include('salesforce_phone_raw' => '(11) 3333-4444')
        expect(result[:warnings].first).to eq(
          I18n.t('apps.salesforce.transforms.invalid_phone', value: '(11) 3333-4444')
        )
      end

      it 'converts the phone when the mapping carries the country code to apply' do
        mapping = build(:apps_salesforce_object_mappings, app: salesforce,
                                                          options: { 'country_code' => '55' },
                                                          field_mappings: [
                                                            { 'salesforce_field' => 'Phone',
                                                              'woofed_field' => 'phone', 'kind' => 'attribute' }
                                                          ])

        result = described_class.new(mapping, payload.merge('Phone' => '(11) 3333-4444')).call

        expect(result[:ok][:attributes]).to eq('phone' => '+551133334444')
        expect(result[:warnings]).to be_empty
      end
    end

    context 'when the mapping has an incomplete row' do
      it 'skips it rather than writing an empty field' do
        mapping = build(:apps_salesforce_object_mappings, app: salesforce, field_mappings: [
                          { 'salesforce_field' => 'Name', 'woofed_field' => '', 'kind' => 'attribute' },
                          { 'salesforce_field' => '', 'woofed_field' => 'name', 'kind' => 'attribute' }
                        ])

        result = described_class.new(mapping, payload).call

        expect(result[:ok][:attributes]).to be_empty
      end
    end

    context 'when salesforce sent the field empty' do
      it 'writes the emptiness, since the user cleared the value on their side' do
        mapping = build(:apps_salesforce_object_mappings, app: salesforce, field_mappings: [
                          { 'salesforce_field' => 'Name', 'woofed_field' => 'name', 'kind' => 'attribute' }
                        ])

        result = described_class.new(mapping, payload.merge('Name' => '')).call

        expect(result[:ok][:attributes]).to eq('name' => nil)
      end
    end

    context 'when salesforce did not send the field at all' do
      it 'leaves the woofed field untouched, since a partial payload says nothing about it' do
        mapping = build(:apps_salesforce_object_mappings, app: salesforce, field_mappings: [
                          { 'salesforce_field' => 'Name', 'woofed_field' => 'name', 'kind' => 'attribute' },
                          { 'salesforce_field' => 'Website', 'woofed_field' => 'site_url', 'kind' => 'attribute' }
                        ])

        result = described_class.new(mapping, payload).call

        expect(result[:ok][:attributes]).to eq('name' => 'Acme Ltda')
      end
    end
  end
end
