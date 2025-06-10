require 'rails_helper'

RSpec.describe Reports::Deals::Timeseries::CountReportBuilder do
  let(:account) { create(:account) }
  let(:stage) { create(:stage) }
  let(:params) do
    { metric: 'won_deals_count', id: stage.id, type: 'stage', group_by: 'day', timezone_offset: '-03:00' }
  end
  let(:range) { Date.today.beginning_of_month..Date.today.end_of_month }
  let(:scope_mock) { instance_double(ActiveRecord::Relation) }

  before do
    allow_any_instance_of(described_class).to receive(:range).and_return(range)
    allow_any_instance_of(described_class).to receive(:timezone).and_return('America/Sao_Paulo')
    allow_any_instance_of(described_class).to receive(:object_scope).and_return(scope_mock)
  end

  describe '#aggregate_value' do
    it 'returns count from object_scope' do
      allow(scope_mock).to receive(:count).and_return(10)
      instance = described_class.new(account, params)
      expect(instance.aggregate_value).to eq(10)
    end
  end

  describe '#grouped_count' do
    it 'groups by period with count' do
      grouped_data = { Date.today => 10, Date.yesterday => 5 }
      allow(scope_mock).to receive(:group_by_period).with(
        'day',
        :won_at,
        default_value: 0,
        range:,
        permit: %w[day week month year hour],
        time_zone: 'America/Sao_Paulo'
      ).and_return(scope_mock)
      allow(scope_mock).to receive(:count).and_return(grouped_data)
      instance = described_class.new(account, params.merge(metric: 'won_deals_count'))
      expect(instance.send(:grouped_count)).to eq(grouped_data)
    end
  end
end
