# spec/models/apps/salesforce/record_id_spec.rb
require 'rails_helper'

RSpec.describe Apps::Salesforce::RecordId do
  describe '.call' do
    context 'when the id is the 15 character form' do
      it 'appends the three characters that encode its capitalisation' do
        expect(described_class.call('001Hn00001AbCdE')).to eq('001Hn00001AbCdEIAV')
        expect(described_class.call('003Hn00002XyZwV')).to eq('003Hn00002XyZwVIAV')
      end

      it 'ignores surrounding whitespace, since ids get pasted by hand' do
        expect(described_class.call('  001Hn00001AbCdE ')).to eq('001Hn00001AbCdEIAV')
      end
    end

    context 'when the id is already the 18 character form' do
      it 'leaves it untouched, so converting twice is safe' do
        expect(described_class.call('001Hn00001AbCdEIAV')).to eq('001Hn00001AbCdEIAV')
      end
    end

    context 'when there is no id to convert' do
      it 'returns an empty string rather than failing' do
        expect(described_class.call(nil)).to eq('')
        expect(described_class.call('')).to eq('')
      end
    end
  end
end
