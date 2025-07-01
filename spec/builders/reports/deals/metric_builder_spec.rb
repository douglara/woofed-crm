require 'rails_helper'

RSpec.describe Reports::Deals::MetricBuilder do
  let(:account) { create(:account) }
  let(:params) { { metric: 'won_deals', id: '1', type: 'stage' } }
  let(:subject) { described_class.new(account, params) }
  let(:count_builder_mock) { instance_double(Reports::Deals::Timeseries::CountReportBuilder) }
  let(:sum_builder_mock) { instance_double(Reports::Deals::Timeseries::SumReportBuilder) }

  describe '#summary' do
    before do
      allow_any_instance_of(described_class).to receive(:builder_class).with('won_deals_count').and_return(Reports::Deals::Timeseries::CountReportBuilder)
      allow_any_instance_of(described_class).to receive(:builder_class).with('won_deals_sum').and_return(Reports::Deals::Timeseries::SumReportBuilder)
      allow(Reports::Deals::Timeseries::CountReportBuilder).to receive(:new).and_return(count_builder_mock)
      allow(Reports::Deals::Timeseries::SumReportBuilder).to receive(:new).and_return(sum_builder_mock)
      allow(count_builder_mock).to receive(:aggregate_value).and_return(5)
      allow(sum_builder_mock).to receive(:aggregate_value).and_return(500)
      allow(I18n).to receive(:t).with('activerecord.models.deal.won_deals').and_return('Won Deals')
    end

    it 'returns summary with title, amount_in_cents, and quantity' do
      expect(subject.summary).to eq({
                                       title: 'Won Deals',
                                       amount_in_cents: 500,
                                       quantity: 5
                                     })
    end
  end

  describe '#fetch_summary_name' do
    %w[open_deals lost_deals won_deals all_deals].each do |metric|
      context "when metric is #{metric}" do
        let(:params) { { metric: } }
        it "returns translated name for #{metric}" do
          translation_key = "activerecord.models.deal.#{metric == 'all_deals' ? 'created_deals' : metric}"
          expected_name = metric.capitalize
          allow(I18n).to receive(:t).with(translation_key).and_return(expected_name)
          expect(subject.send(:fetch_summary_name)).to eq(expected_name)
        end
      end
    end
  end
end
