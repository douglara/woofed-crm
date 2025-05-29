require 'rails_helper'

RSpec.describe ReportBuilder do
  let(:account) { create(:account) }
  let(:params) { {} }
  let(:starts_date) { Date.new(2025, 1, 1) }
  let(:ends_date) { Date.new(2025, 1, 31) }
  let(:date_range) { "#{starts_date.strftime('%d/%m/%Y')} - #{ends_date.strftime('%d/%m/%Y')}" }
  let(:builder) { described_class.new(account, params) }

  describe '#initialize' do
    context 'when date_range is provided in params' do
      let(:params) { { date_range: '01/01/2025 - 31/01/2025' } }

      it 'sets starts_date_range and ends_date_range correctly' do
        expect(builder.starts_date_range).to eq(Date.new(2025, 1, 1))
        expect(builder.ends_date_range).to eq(Date.new(2025, 1, 31))
      end
    end

    context 'when date_range is not provided' do
      it 'sets default date range (last month to today)' do
        travel_to Date.new(2025, 2, 1) do
          expect(builder.starts_date_range).to eq(Date.new(2025, 1, 1))
          expect(builder.ends_date_range).to eq(Date.new(2025, 2, 1))
          expect(builder.params[:date_range]).to eq('01/01/2025 - 01/02/2025')
        end
      end
    end
  end

  describe '#build' do
    let(:pipeline) { create(:pipeline, account:) }

    context 'with valid metric' do
      before { create(:stage, pipeline:) }

      it 'calls summary when metric is :summary' do
        expect(builder).to receive(:summary).and_call_original
        builder.build(:summary)
      end

      it 'calls pipeline_summary when metric is :pipeline_summary' do
        expect(builder).to receive(:pipeline_summary).and_call_original
        builder.build(:pipeline_summary)
      end
    end

    context 'with invalid metric' do
      it 'returns empty hash' do
        expect(builder.build(:invalid_metric)).to eq({})
      end
    end
  end

  describe '#build (summary)' do
    let(:params) { { date_range: } }
    let(:pipeline) { create(:pipeline, account:) }
    let(:stage) { create(:stage, pipeline:) }

    before do
      create(:deal, status: :open, account:, created_at: starts_date, total_deal_products_amount_in_cents: 1000)
      create(:deal, status: :won, account:, created_at: starts_date, won_at: starts_date,
                    total_deal_products_amount_in_cents: 2000)
      create(:deal, status: :lost, account:, created_at: starts_date, lost_at: starts_date,
                    total_deal_products_amount_in_cents: 3000)
      create(:deal, account:, created_at: starts_date, total_deal_products_amount_in_cents: 4000)
    end

    it 'builds summaries with correct titles, amounts, and counts' do
      result = builder.build(:summary)[:summaries]
      expect(result).to contain_exactly(
        hash_including(title: I18n.t('activerecord.models.deal.open_deals'), amount: 5000, count: 2),
        hash_including(title: I18n.t('activerecord.models.deal.created_deals'), amount: 10_000, count: 4),
        hash_including(title: I18n.t('activerecord.models.deal.won_deals'), amount: 2000, count: 1),
        hash_including(title: I18n.t('activerecord.models.deal.lost_deals'), amount: 3000, count: 1)
      )
    end

    it 'builds column chart data with correct categories and series' do
      result = builder.build(:summary)[:column_chart_data]
      expect(result[:categories]).to include('Jan 2025')
      expect(result[:series]).to contain_exactly(
        hash_including(name: I18n.t('activerecord.models.deal.won_deals'), data: [1]),
        hash_including(name: I18n.t('activerecord.models.deal.lost_deals'), data: [1])
      )
    end
  end

  describe '#build (pipeline_summary)' do
    let(:params) { { date_range:, pipeline_id: pipeline.id } }
    let(:pipeline) { create(:pipeline, account:) }
    let(:stage1) { create(:stage, pipeline:, name: 'Stage 1') }
    let(:stage2) { create(:stage, pipeline:, name: 'Stage 2') }

    before do
      create(:deal, account:, pipeline:, stage: stage1, created_at: starts_date)
      create(:deal, account:, pipeline:, stage: stage2, created_at: starts_date)
    end

    it 'builds funnel chart data with correct categories and series' do
      result = builder.build(:pipeline_summary)[:funnel_chart_data]
      expect(result[:categories]).to eq(['Stage 1', 'Stage 2'])
      expect(result[:series]).to eq([{ name: pipeline.name, data: [1, 1] }])
    end

    context 'when pipeline_id is not provided' do
      let(:params) { { date_range: } }

      it 'uses the first pipeline' do
        result = builder.build(:pipeline_summary)[:funnel_chart_data]
        expect(result[:series][0][:name]).to eq(pipeline.name)
      end
    end
  end

  describe '#build_funnel_chart_data' do
    let!(:pipeline) { create(:pipeline, account:) }
    let!(:stage) { create(:stage, pipeline:, name: 'Stage 1') }
    let(:params) { { date_range:, pipeline_id: pipeline.id } }

    it 'returns data for stages with no deals' do
      result = builder.send(:build_funnel_chart_data)
      expect(result[:categories]).to eq(['Stage 1'])
      expect(result[:series][0][:data]).to eq([0])
    end

    context 'when no pipeline exists' do
      let(:params) { { date_range:, pipeline_id: -1 } }

      before do
        Stage.delete_all
        Pipeline.delete_all
      end

      it 'returns an empty hash when pipeline is blank' do
        result = builder.send(:build_funnel_chart_data)
        expect(result).to eq({})
      end
    end
  end

  describe '#build_column_chart_data' do
    let(:params) { { date_range: } }

    before do
      create(:deal, :won, account:, won_at: starts_date)
      create(:deal, :lost, account:, lost_at: starts_date)
    end

    it 'groups deals by month and returns correct categories and series' do
      result = builder.send(:build_column_chart_data)
      expect(result[:categories]).to include('Jan 2025')
      expect(result[:series][0][:data]).to eq([1])
      expect(result[:series][1][:data]).to eq([1])
    end
  end

  describe '#set_date_range' do
    context 'with invalid date format' do
      let(:params) { { date_range: 'invalid - format' } }

      it 'raises ArgumentError' do
        expect { builder.send(:set_date_range) }.to raise_error(ArgumentError)
      end
    end
  end
end
