# spec/models/apps/salesforce/transform/value_spec.rb
require 'rails_helper'

RSpec.describe Apps::Salesforce::Transform::Value do
  describe '.call' do
    context 'when the transform is text' do
      it 'trims the value and treats a blank cell as nothing, since csv has no null' do
        expect(described_class.call('text', '  Acme Ltda ')).to eq(ok: 'Acme Ltda')
        expect(described_class.call('text', '')).to eq(ok: nil)
        expect(described_class.call('text', nil)).to eq(ok: nil)
      end
    end

    context 'when the transform is currency_to_cents' do
      it 'converts the decimal salesforce sends into the cents woofed stores' do
        expect(described_class.call('currency_to_cents', '1500.50')).to eq(ok: 150_050)
        expect(described_class.call('currency_to_cents', 1500)).to eq(ok: 150_000)
        expect(described_class.call('currency_to_cents', '')).to eq(ok: nil)
      end

      it 'reports a value that is not an amount and keeps the original' do
        result = described_class.call('currency_to_cents', 'R$ mil')

        expect(result[:error]).to eq(I18n.t('apps.salesforce.transforms.invalid_currency', value: 'R$ mil'))
        expect(result[:raw]).to eq('R$ mil')
      end
    end

    context 'when the transform is datetime' do
      it 'parses both the rest and the bulk csv formats' do
        expect(described_class.call('datetime', '2026-08-01T14:22:31.000+0000')[:ok])
          .to eq(Time.utc(2026, 8, 1, 14, 22, 31))
        expect(described_class.call('datetime', '2026-08-01T14:22:31.000Z')[:ok])
          .to eq(Time.utc(2026, 8, 1, 14, 22, 31))
      end

      it 'stores an offsetless value as UTC, so the browser renders it in the viewer timezone' do
        result = described_class.call('datetime', '2026-08-01')

        expect(result[:ok]).to eq(Time.utc(2026, 8, 1))
        expect(result[:ok].utc_offset).to eq(0)
      end

      it 'reports a value that is not a date and keeps the original' do
        result = described_class.call('datetime', 'ontem')

        expect(result[:error]).to eq(I18n.t('apps.salesforce.transforms.invalid_datetime', value: 'ontem'))
        expect(result[:raw]).to eq('ontem')
      end

      it 'reports a date shaped value that no calendar has' do
        result = described_class.call('datetime', '2026-13-45')

        expect(result[:error]).to eq(I18n.t('apps.salesforce.transforms.invalid_datetime', value: '2026-13-45'))
        expect(result[:raw]).to eq('2026-13-45')
      end
    end

    context 'when the transform is picklist_to_label_list' do
      it 'splits the semicolon delimited field a multi select picklist arrives in' do
        expect(described_class.call('picklist_to_label_list', 'Varejo;Saúde')).to eq(ok: %w[Varejo Saúde])
        expect(described_class.call('picklist_to_label_list', 'Varejo; ;Saúde')).to eq(ok: %w[Varejo Saúde])
        expect(described_class.call('picklist_to_label_list', '')).to eq(ok: [])
      end
    end

    context 'when the transform is boolean' do
      it 'accepts both the real booleans of rest and the strings of bulk csv' do
        expect(described_class.call('boolean', true)).to eq(ok: true)
        expect(described_class.call('boolean', 'true')).to eq(ok: true)
        expect(described_class.call('boolean', 'false')).to eq(ok: false)
        expect(described_class.call('boolean', '0')).to eq(ok: false)
        expect(described_class.call('boolean', nil)).to eq(ok: nil)
      end
    end

    context 'when the transform does not exist' do
      it 'reports it instead of importing the value untouched' do
        result = described_class.call('shout', 'Acme')

        expect(result[:error]).to eq(I18n.t('apps.salesforce.transforms.unknown', name: 'shout'))
        expect(result[:raw]).to eq('Acme')
      end
    end
  end
end
