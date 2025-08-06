require 'rails_helper'

RSpec.describe Reports::Deals::Timeseries::SumReportBuilder do
  let(:account) { create(:account) }
  let(:start_date) { Date.today.beginning_of_month } 
  let(:end_date) { Date.today.end_of_month } 
  let(:range) { start_date..end_date }
  let!(:deal1) do
    create(:deal, :won, account:, won_at: start_date + 1.day,
                        created_at: start_date - 2.days, total_deal_products_amount_in_cents: 1000)
  end
  let!(:deal2) do
    create(:deal, :won, account:, won_at: start_date + 2.days,
                        created_at: start_date - 2.days, total_deal_products_amount_in_cents: 4000)
  end
  let!(:deal3) do
    create(:deal, :won, account:, won_at: start_date + 10.days,
                        created_at: start_date - 20.days, total_deal_products_amount_in_cents: 5000)
  end
  let(:won_deals) { Deal.won }

  before do
    allow_any_instance_of(described_class).to receive(:range).and_return(range)
    allow_any_instance_of(described_class).to receive(:object_scope).and_return(won_deals)
  end

  describe '#aggregate_value' do
    it 'returns sum from object_scope' do
      instance = described_class.new(account, {})
      expect(instance.aggregate_value).to eq(10_000)
    end
  end

  describe '#grouped_count' do
    let(:params) do
      { metric: 'won_deals_sum', type: 'account', group_by:, timezone_offset: }
    end

    context 'with UTC timezone (-00:00)' do
      let(:timezone_offset) { '-00:00' }

      context 'groups by period (day) with sum' do
        let(:group_by) { 'day' }
        it do
          expected_result = (start_date..end_date).each_with_object({}) do |date, hash|
            hash[date] = 0
          end
          expected_result[start_date + 1.day] = 1000 
          expected_result[start_date + 2.days] = 4000 
          expected_result[start_date + 10.days] = 5000 

          instance = described_class.new(account, params)
          expect(instance.send(:grouped_count)).to eq(expected_result)
        end
      end

      context 'groups by period (month) with sum' do
        let(:group_by) { 'month' }
        let(:expected_result) do
          { start_date.beginning_of_month => 10_000 } 
        end
        it do
          instance = described_class.new(account, params)
          expect(instance.send(:grouped_count)).to eq(expected_result)
        end
      end

      context 'groups by period (year) with sum' do
        let(:group_by) { 'year' }
        let(:expected_result) do
          { start_date.beginning_of_year => 10_000 } 
        end
        it do
          instance = described_class.new(account, params)
          expect(instance.send(:grouped_count)).to eq(expected_result)
        end
      end
    end

    context 'with Brazil timezone (-03:00)' do
      let(:timezone_offset) { '-03:00' }

      context 'groups by period (day) with sum' do
        let(:group_by) { 'day' }
        it do
          expected_result = (start_date..end_date).each_with_object({}) do |date, hash|
            hash[date] = 0
          end

          expected_result[start_date] = 1000 
          expected_result[start_date + 1.day] = 4000 
          expected_result[start_date + 9.days] = 5000 

          instance = described_class.new(account, params)
          expect(instance.send(:grouped_count)).to eq(expected_result)
        end
      end
    end
  end
end
