require 'rails_helper'

RSpec.describe Reports::Deals::Timeseries::SumReportBuilder do
  let(:account) { create(:account) }
  let(:stage) { create(:stage) }
  let(:params) { { metric: 'won_deals_sum', id: stage.id, type: 'stage', group_by: 'day', timezone_offset: '-03:00' } }
  let(:range) { Date.today.beginning_of_month..Date.today.end_of_month }
  let(:scope_mock) { instance_double(ActiveRecord::Relation) }

  before do
    allow_any_instance_of(described_class).to receive(:range).and_return(range)
    allow_any_instance_of(described_class).to receive(:timezone).and_return('America/Sao_Paulo')
    allow_any_instance_of(described_class).to receive(:object_scope).and_return(scope_mock)
  end

  describe '#aggregate_value' do
    it 'returns sum from object_scope' do
      allow(scope_mock).to receive(:sum).with(:total_deal_products_amount_in_cents).and_return(500)
      instance = described_class.new(account, params)
      expect(instance.aggregate_value).to eq(500)
    end
  end

  describe '#grouped_count' do
    it 'groups by period with sum' do
      grouped_data = { Date.today => 500, Date.yesterday => 300 }
      allow(scope_mock).to receive(:group_by_period).with(
        'day',
        :won_at,
        default_value: 0,
        range:,
        permit: %w[day week month year hour],
        time_zone: 'America/Sao_Paulo'
      ).and_return(scope_mock)
      allow(scope_mock).to receive(:sum).with(:total_deal_products_amount_in_cents).and_return(grouped_data)
      instance = described_class.new(account, params)
      expect(instance.send(:grouped_count)).to eq(grouped_data)
    end
  end
end
