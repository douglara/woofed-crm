require 'rails_helper'

RSpec.describe Reports::Deals::ReportBuilder do
  let(:account) { create(:account) }
  let(:params) { { metric: 'won_deals_count', id: '1', type: 'stage' } }
  let(:builder_mock) { instance_double(Reports::Deals::Timeseries::CountReportBuilder) }
  let(:subject) { described_class.new(account, params) }

  describe '#initialize' do
    it 'raises ArgumentError when account is nil' do
      expect { described_class.new(nil, params) }.to raise_error(ArgumentError, 'account is required')
    end

    it 'raises ArgumentError when params is nil' do
      expect { described_class.new(account, nil) }.to raise_error(ArgumentError, 'params is required')
    end
  end

  describe '#timeseries' do
    context 'with valid metric' do
      before do
        allow_any_instance_of(described_class).to receive(:builder).and_return(Reports::Deals::Timeseries::CountReportBuilder)
        allow(Reports::Deals::Timeseries::CountReportBuilder).to receive(:new).with(account,
                                                                                    params).and_return(builder_mock)
        allow(builder_mock).to receive(:timeseries).and_return([{ value: 10, timestamp: 1_234_567_890 }])
      end

      it 'returns timeseries from builder' do
        expect(subject.timeseries).to eq([{ value: 10, timestamp: 1_234_567_890 }])
      end
    end

    context 'with invalid metric' do
      let(:params) { { metric: 'invalid_metric', id: '1', type: 'stage' } }
      it 'logs error and returns empty hash' do
        expect(Rails.logger).to receive(:error).with('ReportBuilder: Invalid metric - invalid_metric')
        expect(subject.timeseries).to eq({})
      end
    end
  end

  describe '#aggregate_value' do
    context 'with valid metric' do
      before do
        allow_any_instance_of(described_class).to receive(:builder).and_return(Reports::Deals::Timeseries::CountReportBuilder)
        allow(Reports::Deals::Timeseries::CountReportBuilder).to receive(:new).with(account,
                                                                                    params).and_return(builder_mock)
        allow(builder_mock).to receive(:aggregate_value).and_return(100)
      end

      it 'returns aggregate value from builder' do
        expect(subject.aggregate_value).to eq(100)
      end
    end

    context 'with invalid metric' do
      let(:params) { { metric: 'invalid_metric', id: '1', type: 'stage' } }
      it 'logs error and returns empty hash' do
        expect(Rails.logger).to receive(:error).with('ReportBuilder: Invalid metric - invalid_metric')
        expect(subject.aggregate_value).to eq({})
      end
    end
  end
end
