require 'rails_helper'

RSpec.describe Reports::Deals::Timeseries::CountReportBuilder do
  let(:account) { create(:account) }
  let(:start_date) { Date.today.beginning_of_month }
  let(:end_date) { Date.today.end_of_month }
  let(:range) { start_date..end_date }
  let!(:deal1) do
    create(:deal, :won, account:, won_at: start_date + 1.day,
                        created_at: start_date - 2.days)
  end
  let!(:deal2) do
    create(:deal, :won, account:, won_at: start_date + 2.days,
                        created_at: start_date - 2.days)
  end
  let!(:deal3) do
    create(:deal, :won, account:, won_at: start_date + 10.days,
                        created_at: start_date - 20.days)
  end
  let(:won_deals) { Deal.won }

  before do
    allow_any_instance_of(described_class).to receive(:range).and_return(range)
    allow_any_instance_of(described_class).to receive(:object_scope).and_return(won_deals)
  end

  describe '#aggregate_value' do
    it 'returns count from object_scope' do
      instance = described_class.new(account, {})
      expect(instance.aggregate_value).to eq(3)
    end
  end

  describe '#grouped_count' do
    let(:params) do
      { metric: 'won_deals_count', type: 'account', group_by:, timezone_offset: }
    end

    context 'with UTC timezone (-00:00)' do
      let(:timezone_offset) { '-00:00' }

      context 'groups by period (day) with count' do
        let(:group_by) { 'day' }
        it do
          expected_result = (start_date..end_date).each_with_object({}) do |date, hash|
            hash[date] = 0
          end
          expected_result[start_date + 1.day] = 1
          expected_result[start_date + 2.days] = 1
          expected_result[start_date + 10.days] = 1

          instance = described_class.new(account, params)
          expect(instance.send(:grouped_count)).to eq(expected_result)
        end
      end

      context 'groups by period (month) with count' do
        let(:group_by) { 'month' }
        let(:expected_result) do
          { range.begin.beginning_of_month => 3 }
        end
        it do
          instance = described_class.new(account, params)
          expect(instance.send(:grouped_count)).to eq(expected_result)
        end
      end

      context 'groups by period (year) with count' do
        let(:group_by) { 'year' }
        let(:expected_result) do
          { range.begin.beginning_of_year => 3 }
        end
        it do
          instance = described_class.new(account, params)
          expect(instance.send(:grouped_count)).to eq(expected_result)
        end
      end
    end

    context 'with Brazil timezone (-03:00)' do
      let(:timezone_offset) { '-03:00' }

      context 'groups by period (day) with count' do
        let(:group_by) { 'day' }
        it do
          expected_result = (start_date..end_date).each_with_object({}) do |date, hash|
            hash[date] = 0
          end

          expected_result[start_date] = 1
          expected_result[start_date + 1.day] = 1
          expected_result[start_date + 9.days] = 1

          instance = described_class.new(account, params)
          expect(instance.send(:grouped_count)).to eq(expected_result)
        end
      end
    end
  end
end
