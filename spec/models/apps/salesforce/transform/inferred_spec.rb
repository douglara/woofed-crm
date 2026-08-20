# spec/models/apps/salesforce/transform/inferred_spec.rb
require 'rails_helper'

RSpec.describe Apps::Salesforce::Transform::Inferred do
  describe '.call' do
    context 'when the target column says what the value has to become' do
      it 'reads cents, dates and booleans off the column definition' do
        expect(described_class.call('Deal', 'total_amount_in_cents')).to eq('currency_to_cents')
        expect(described_class.call('Deal', 'won_at')).to eq('datetime')
        expect(described_class.call('Contact', 'full_name')).to eq('text')
      end

      it 'normalises anything landing in a phone column' do
        expect(described_class.call('Contact', 'phone')).to eq('phone')
        expect(described_class.call('Company', 'phone')).to eq('phone')
      end
    end

    context 'when the target is a custom attribute' do
      it 'falls back to text, since jsonb has no column type to read' do
        expect(described_class.call('Company', 'industria', kind: 'custom_attribute')).to eq('text')
      end
    end

    context 'when the model or the column is unknown' do
      it 'falls back to text instead of failing the mapping' do
        expect(described_class.call('Product', 'name')).to eq('text')
        expect(described_class.call('Contact', 'does_not_exist')).to eq('text')
      end
    end
  end
end
