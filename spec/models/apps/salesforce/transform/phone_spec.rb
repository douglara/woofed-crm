# spec/models/apps/salesforce/transform/phone_spec.rb
require 'rails_helper'

RSpec.describe Apps::Salesforce::Transform::Phone do
  describe '.call' do
    context 'when the number already carries a country code' do
      it 'strips the formatting salesforce allows and keeps E.164' do
        expect(described_class.call('+55 11 99999 9999')).to eq(ok: '+5511999999999')
        expect(described_class.call('+55 (11) 99999-9999')).to eq(ok: '+5511999999999')
      end

      it 'drops an extension, which is never part of the number' do
        expect(described_class.call('+551133334444 ext. 204')).to eq(ok: '+551133334444')
      end
    end

    context 'when a country code is configured for the mapping' do
      it 'applies it to a local number, dropping the trunk zero' do
        expect(described_class.call('(11) 99999-9999', 'country_code' => '55')).to eq(ok: '+5511999999999')
        expect(described_class.call('011 3333-4444', 'country_code' => '55')).to eq(ok: '+551133334444')
      end
    end

    context 'when the number has no country code and none is configured' do
      it 'reports it rather than guessing a country nobody can call back' do
        result = described_class.call('(11) 99999-9999')

        expect(result[:error]).to eq(I18n.t('apps.salesforce.transforms.invalid_phone', value: '(11) 99999-9999'))
        expect(result[:raw]).to eq('(11) 99999-9999')
      end
    end

    context 'when there is nothing that looks like a number' do
      it 'reports it' do
        expect(described_class.call('ramal interno', 'country_code' => '55')[:error]).to be_present
      end
    end

    context 'when the field is empty' do
      it 'returns nothing to write' do
        expect(described_class.call('')).to eq(ok: nil)
      end
    end
  end
end
