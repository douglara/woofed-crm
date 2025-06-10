require 'rails_helper'

RSpec.describe Reports::Deals::BaseReportBuilder do
  let(:account) { create(:account) }
  let(:params) { { metric: 'won_deals_count' } }
  let(:subject) { described_class.new(account, params) }

  describe '#initialize' do
    it 'raises ArgumentError when account is nil' do
      expect { described_class.new(nil, params) }.to raise_error(ArgumentError, 'account is required')
    end

    it 'raises ArgumentError when params is nil' do
      expect { described_class.new(account, nil) }.to raise_error(ArgumentError, 'params is required')
    end
  end

  describe '#builder_class' do
    context 'with count metrics' do
      Reports::Deals::BaseReportBuilder::COUNT_METRICS.each do |metric|
        it "returns CountReportBuilder for #{metric}" do
          subject = described_class.new(account, metric:)
          expect(subject.send(:builder_class, metric)).to eq(Reports::Deals::Timeseries::CountReportBuilder)
        end
      end
    end

    context 'with sum metrics' do
      Reports::Deals::BaseReportBuilder::SUM_METRICS.each do |metric|
        it "returns SumReportBuilder for #{metric}" do
          subject = described_class.new(account, metric:)
          expect(subject.send(:builder_class, metric)).to eq(Reports::Deals::Timeseries::SumReportBuilder)
        end
      end
    end

    context 'with invalid metric' do
      it 'returns nil' do
        subject = described_class.new(account, metric: 'invalid_metric')
        expect(subject.send(:builder_class, 'invalid_metric')).to be_nil
      end
    end
  end

  describe '#log_invalid_metric' do
    it 'logs error and returns empty hash' do
      subject = described_class.new(account, metric: 'invalid_metric')
      expect(Rails.logger).to receive(:error).with('ReportBuilder: Invalid metric - invalid_metric')
      expect(subject.send(:log_invalid_metric)).to eq({})
    end
  end
end
