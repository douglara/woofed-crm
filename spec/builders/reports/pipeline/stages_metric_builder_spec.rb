require 'rails_helper'

RSpec.describe Reports::Pipeline::StagesMetricBuilder do
  let(:account) { create(:account) }
  let!(:pipeline) { create(:pipeline, account:) }
  let!(:stage1) { create(:stage, pipeline:, position: 1, name: 'Stage 1') }
  let!(:stage2) { create(:stage, pipeline:, position: 2, name: 'Stage 2') }
  let(:params) { { id: pipeline.id, metric: 'won_deals' } }
  let(:report_builder_mock) { instance_double(Reports::Deals::ReportBuilder) }

  describe '#initialize' do
    it 'raises ArgumentError when account is nil' do
      expect { described_class.new(nil, params) }.to raise_error(ArgumentError, 'account is required')
    end

    it 'raises ArgumentError when params is nil' do
      expect { described_class.new(account, nil) }.to raise_error(ArgumentError, 'params is required')
    end

    it 'sets account and params' do
      instance = described_class.new(account, params)
      expect(instance.send(:account)).to eq(account)
      expect(instance.send(:params)).to eq(params)
    end
  end

  describe '#metrics' do
    let(:subject) { described_class.new(account, params).metrics }

    context 'with valid deal status' do
      before do
        allow(Reports::Deals::ReportBuilder).to receive(:new).and_return(report_builder_mock)
        allow(report_builder_mock).to receive(:aggregate_value).and_return(10, 20)
      end

      it 'returns metrics hash with stage names and aggregate values' do
        expect(subject).to eq('Stage 1' => 10, 'Stage 2' => 20)
      end

      it 'calls ReportBuilder with correct params for each stage' do
        expect(Reports::Deals::ReportBuilder).to receive(:new).with(
          account,
          hash_including(metric: 'won_deals_count', id: stage1.id, type: :stage)
        ).once
        expect(Reports::Deals::ReportBuilder).to receive(:new).with(
          account,
          hash_including(metric: 'won_deals_count', id: stage2.id, type: :stage)
        ).once
        subject
      end
    end

    context 'with invalid metric deal status' do
      let(:params) { { id: pipeline.id, metric: 'invalid_metric' } }

      it 'raises ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'invalid metric')
      end
    end
  end

  describe '#valid_deal_status?' do
    let(:subject) { described_class.new(account, params).send(:valid_deal_status?) }

    %w[won_deals lost_deals open_deals all_deals].each do |metric|
      context "when metric is #{metric}" do
        let(:params) { { id: pipeline.id, metric: } }

        it 'returns true' do
          expect(subject).to be true
        end
      end
    end

    context 'when metric is invalid' do
      let(:params) { { id: pipeline.id, metric: 'invalid' } }

      it 'returns false' do
        expect(subject).to be false
      end
    end
  end

  describe '#pipeline' do
    let(:subject) { described_class.new(account, params) }
    it 'returns pipeline based on params id' do
      allow(Pipeline).to receive(:find).with(pipeline.id).and_return(pipeline)
      expect(subject.send(:pipeline)).to eq(pipeline)
    end

    context 'raises ActiveRecord::RecordNotFound when pipeline id is not found' do
      let(:params) { { id: 'invalid_id', metric: 'won_deals' } }
      it do
        allow(Pipeline).to receive(:find).with('invalid_id').and_raise(ActiveRecord::RecordNotFound)
        expect { subject.send(:pipeline) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
