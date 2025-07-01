require 'rails_helper'

RSpec.describe Reports::Deals::Timeseries::BaseReportBuilder do
  let(:account) { create(:account) }
  let(:stage) { create(:stage, account:) }

  describe '#timeseries' do
    let(:grouped_count_mock) do
      {
        Time.zone.parse('2025-06-07').to_date => 0,
        Time.zone.parse('2025-06-08').to_date => 0,
        Time.zone.parse('2025-06-09').to_date => 0,
        Time.zone.parse('2025-06-10').to_date => 1,
        Time.zone.parse('2025-06-11').to_date => 1,
        Time.zone.parse('2025-06-12').to_date => 0,
        Time.zone.parse('2025-06-13').to_date => 0
      }
    end

    context 'returns the expected timeseries with correct timestamps and values' do
      before do
        allow_any_instance_of(described_class).to receive(:grouped_count).and_return(grouped_count_mock)
      end
      let(:params) do
        {
          metric: 'won_deals_count',
          type: :stage,
          id: stage.id,
          since: (Time.zone.today - 3.days).to_time.to_i.to_s,
          until: Time.zone.today.end_of_day.to_i.to_s,
          group_by: 'day',
          timezone_offset: '-03:00'
        }
      end

      let(:expected_result) do
        [
          { value: 0, timestamp: 1_749_265_200 },
          { value: 0, timestamp: 1_749_351_600 },
          { value: 0, timestamp: 1_749_438_000 },
          { value: 1, timestamp: 1_749_524_400 },
          { value: 1, timestamp: 1_749_610_800 },
          { value: 0, timestamp: 1_749_697_200 },
          { value: 0, timestamp: 1_749_783_600 }
        ]
      end

      it do
        builder = described_class.new(account, params)
        expect(builder.timeseries).to eq(expected_result)
      end
    end
  end

  describe '#metric' do
    let(:params) { { metric: 'won_deals_count', id: stage.id, type: :stage } }

    it 'strips _count or _sum from metric' do
      instance = described_class.new(account, params)
      expect(instance.send(:metric)).to eq('won_deals')
    end
  end

  describe '#object_scope' do
    let(:params) do
      { metric:, type: :account, since: (Time.zone.today - 5.days).to_time.to_i.to_s,
        until: Time.zone.today.end_of_day.to_i.to_s }
    end

    let!(:won_deal_on_range1) do
      create(:deal, :won, account:, stage:,
                          won_at: Time.zone.today - 1.days,
                          created_at: Time.zone.today - 2.days)
    end

    let!(:won_deal_on_range2) do
      create(:deal, :won, account:, stage:,
                          won_at: Time.zone.today - 2.days,
                          created_at: Time.zone.today - 2.days)
    end

    let!(:won_deal_out_of_range) do
      create(:deal, :won, account:, stage:,
                          won_at: Time.zone.today - 10.days,
                          created_at: Time.zone.today - 20.days)
    end

    let!(:lost_deal_on_range1) do
      create(:deal, :lost, account:, stage:, lost_at: Time.zone.today - 4.days, created_at: Time.zone.today - 2.days)
    end

    let!(:lost_deal_out_of_range) do
      create(:deal, :lost, account:, stage:, lost_at: Time.zone.today - 10.days, created_at: Time.zone.today - 20.days)
    end

    let!(:open_deal_on_range1) do
      create(:deal, :open, account:, stage:, created_at: Time.zone.today)
    end

    let!(:open_deal_out_of_range) do
      create(:deal, :open, account:, stage:, created_at: Time.zone.today - 20.days)
    end

    context 'for won_deals' do
      let(:metric) { 'won_deals_count' }

      it 'returns correct scope for won_deals (scope_for_won_deals)' do
        instance = described_class.new(account, params)
        scope = instance.send(:object_scope)
        expect(scope).to be_a(ActiveRecord::Relation)
        expect(scope).to include(won_deal_on_range1)
        expect(scope).to include(won_deal_on_range2)
        expect(scope).not_to include(won_deal_out_of_range)
        expect(scope).not_to include(lost_deal_on_range1)
        expect(scope).not_to include(lost_deal_out_of_range)
        expect(scope).not_to include(open_deal_on_range1)
        expect(scope).not_to include(open_deal_out_of_range)
      end
    end
    context 'for lost_deals' do
      let(:metric) { 'lost_deals_count' }

      it 'returns correct scope for lost_deals (scope_for_lost_deals)' do
        instance = described_class.new(account, params)
        scope = instance.send(:object_scope)
        expect(scope).to be_a(ActiveRecord::Relation)
        expect(scope).not_to include(won_deal_on_range1)
        expect(scope).not_to include(won_deal_on_range2)
        expect(scope).not_to include(won_deal_out_of_range)
        expect(scope).to include(lost_deal_on_range1)
        expect(scope).not_to include(lost_deal_out_of_range)
        expect(scope).not_to include(open_deal_on_range1)
        expect(scope).not_to include(open_deal_out_of_range)
      end
    end

    context 'for open_deals' do
      let(:metric) { 'open_deals_count' }

      it 'returns correct scope for open_deals (scope_for_open_deals)' do
        instance = described_class.new(account, params)
        scope = instance.send(:object_scope)
        expect(scope).to be_a(ActiveRecord::Relation)
        expect(scope).not_to include(won_deal_on_range1)
        expect(scope).not_to include(won_deal_on_range2)
        expect(scope).not_to include(won_deal_out_of_range)
        expect(scope).not_to include(lost_deal_on_range1)
        expect(scope).not_to include(lost_deal_out_of_range)
        expect(scope).to include(open_deal_on_range1)
        expect(scope).not_to include(open_deal_out_of_range)
      end
    end

    context 'for all_deals' do
      let(:metric) { 'all_deals_count' }

      it 'returns correct scope for all_deals (scope_for_all_deals)' do
        instance = described_class.new(account, params)
        scope = instance.send(:object_scope)
        expect(scope).to be_a(ActiveRecord::Relation)
        expect(scope).to include(won_deal_on_range1)
        expect(scope).to include(won_deal_on_range2)
        expect(scope).not_to include(won_deal_out_of_range)
        expect(scope).to include(lost_deal_on_range1)
        expect(scope).not_to include(lost_deal_out_of_range)
        expect(scope).to include(open_deal_on_range1)
        expect(scope).not_to include(open_deal_out_of_range)
      end
    end
  end

  describe '#grouping_field' do
    context 'when metric is won_deals' do
      it 'returns :won_at' do
        instance = described_class.new(account, metric: 'won_deals')
        expect(instance.send(:grouping_field)).to eq(:won_at)
      end
    end

    context 'when metric is lost_deals' do
      it 'returns :lost_at' do
        instance = described_class.new(account, metric: 'lost_deals')
        expect(instance.send(:grouping_field)).to eq(:lost_at)
      end
    end

    context 'when metric is open_deals' do
      it 'returns :created_at' do
        instance = described_class.new(account, metric: 'open_deals')
        expect(instance.send(:grouping_field)).to eq(:created_at)
      end
    end

    context 'when metric is all_deals' do
      it 'returns :created_at' do
        instance = described_class.new(account, metric: 'all_deals')
        expect(instance.send(:grouping_field)).to eq(:created_at)
      end
    end
  end
end
