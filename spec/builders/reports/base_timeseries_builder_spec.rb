require 'rails_helper'

RSpec.describe Reports::BaseTimeseriesBuilder do
  let(:account) { create(:account) }
  let(:stage) { create(:stage) }
  let(:params) { { id: stage.id, type: 'stage', group_by: 'day', timezone_offset: '-03:00' } }
  let(:subject) { described_class.new(account, params) }

  describe '#initialize' do
    it 'raises ArgumentError when account is nil' do
      expect { described_class.new(nil, params) }.to raise_error(ArgumentError, 'account is required')
    end

    it 'raises ArgumentError when params is nil' do
      expect { described_class.new(account, nil) }.to raise_error(ArgumentError, 'params is required')
    end
  end

  describe '#scope' do
    context 'when type is :account' do
      let(:params) { { type: 'account' } }
      it 'returns account' do
        expect(subject.scope).to eq(account)
      end
    end

    context 'when type is :stage' do
      it 'returns stage' do
        expect(subject.scope).to eq(stage)
      end
    end
  end

  describe '#stage' do
    it 'returns stage based on params id' do
      expect(subject.stage).to eq(stage)
    end

    context 'raises ActiveRecord::RecordNotFound when stage id is invalid' do
      let(:params) { { id: 'invalid_id', type: 'stage' } }
      it do
        expect { subject.stage }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe '#group_by' do
    %w[day week month year hour].each do |period|
      context "when group_by is #{period}" do
        let(:params) { { group_by: period } }
        it "returns #{period}" do
          expect(subject.group_by).to eq(period)
        end
      end
    end

    context 'when group_by is invalid' do
      let(:params) { { group_by: 'invalid' } }
      it 'returns default group_by' do
        expect(subject.group_by).to eq('month')
      end
    end
  end

  describe '#timezone' do
    it 'returns timezone based on offset' do
      expect(subject).to receive(:timezone_name_from_offset).with('-03:00').and_return('America/Sao_Paulo')
      expect(subject.timezone).to eq('America/Sao_Paulo')
    end
  end
end
