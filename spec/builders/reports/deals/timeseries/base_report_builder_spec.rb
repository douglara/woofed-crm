require 'rails_helper'

RSpec.describe Reports::Deals::Timeseries::BaseReportBuilder, skip: true do
  include ActiveJob::TestHelper

  let(:account) { create(:account) }
  let(:stage) { create(:stage, account:) }

  describe '#timeseries' do
    before do
      travel_to(Time.zone.today) do
        perform_enqueued_jobs do
          # Deals ganhos hoje
          5.times do
            create(:deal, account:, stage:, won_at: Time.zone.today, created_at: Time.zone.today)
          end
          # Deals ganhos há 2 dias
          3.times do
            create(:deal, account:, stage:, won_at: Time.zone.today - 2.days,
                          created_at: Time.zone.today - 2.days)
          end
          # Deals perdidos hoje
          4.times do
            create(:deal, account:, stage:, lost_at: Time.zone.today, created_at: Time.zone.today)
          end
          # Deals abertos hoje
          2.times do
            create(:deal, account:, stage:, created_at: Time.zone.today)
          end
          # Deals abertos há 2 dias
          1.times do
            create(:deal, account:, stage:, created_at: Time.zone.today - 2.days)
          end
        end
      end
    end

    context 'when type is stage' do
      let(:params) do
        {
          metric:,
          type: :stage,
          id: stage.id,
          since: (Time.zone.today - 3.days).to_time.to_i.to_s,
          until: Time.zone.today.end_of_day.to_i.to_s,
          group_by: 'day',
          timezone_offset: '-03:00'
        }
      end

      %w[won_deals_count lost_deals_count open_deals_count all_deals_count].each do |metric|
        context "with metric #{metric}" do
          let(:metric) { metric }

          it "returns timeseries for #{metric}" do
            builder = described_class.new(account, params)
            timeseries = builder.timeseries

            expected = case metric
                       when 'won_deals_count'
                         [
                           { value: 5, timestamp: Time.zone.today.in_time_zone('America/Sao_Paulo').to_i },
                           { value: 3, timestamp: (Time.zone.today - 2.days).in_time_zone('America/Sao_Paulo').to_i }
                         ]
                       when 'lost_deals_count'
                         [
                           { value: 4, timestamp: Time.zone.today.in_time_zone('America/Sao_Paulo').to_i }
                         ]
                       when 'open_deals_count'
                         [
                           { value: 2, timestamp: Time.zone.today.in_time_zone('America/Sao_Paulo').to_i },
                           { value: 1, timestamp: (Time.zone.today - 2.days).in_time_zone('America/Sao_Paulo').to_i }
                         ]
                       when 'all_deals_count'
                         [
                           { value: 11, timestamp: Time.zone.today.in_time_zone('America/Sao_Paulo').to_i },
                           { value: 4, timestamp: (Time.zone.today - 2.days).in_time_zone('America/Sao_Paulo').to_i }
                         ]
                       end

            expect(timeseries).to match_array(expected)
          end
        end
      end

      context 'with invalid metric' do
        let(:metric) { 'invalid_metric' }

        it 'logs error and returns empty array' do
          expect(Rails.logger).to receive(:error).with(/ReportBuilder: Invalid metric - invalid_metric/)
          builder = described_class.new(account, params)
          expect(builder.timeseries).to eq([])
        end
      end

      context 'with invalid group_by' do
        let(:metric) { 'won_deals_count' }
        let(:params) do
          {
            metric:,
            type: :stage,
            id: stage.id,
            since: (Time.zone.today - 3.days).to_time.to_i.to_s,
            until: Time.zone.today.end_of_day.to_i.to_s,
            group_by: 'invalid',
            timezone_offset: '-03:00'
          }
        end

        it 'falls back to default group_by (month)' do
          builder = described_class.new(account, params)
          timeseries = builder.timeseries
          expect(timeseries).to all(include(:value, :timestamp))
          # Verifica que os dados estão agrupados por mês
          expect(timeseries.first[:timestamp]).to eq(Time.zone.today.beginning_of_month.in_time_zone('America/Sao_Paulo').to_i)
        end
      end
    end

    context 'when type is account' do
      let(:params) do
        {
          metric:,
          type: :account,
          since: (Time.zone.today - 3.days).to_time.to_i.to_s,
          until: Time.zone.today.end_of_day.to_i.to_s,
          group_by: 'day',
          timezone_offset: '-03:00'
        }
      end

      %w[won_deals_count lost_deals_count open_deals_count all_deals_count].each do |metric|
        context "with metric #{metric}" do
          let(:metric) { metric }

          it "returns timeseries for #{metric}" do
            builder = described_class.new(account, params)
            timeseries = builder.timeseries

            expected = case metric
                       when 'won_deals_count'
                         [
                           { value: 5, timestamp: Time.zone.today.in_time_zone('America/Sao_Paulo').to_i },
                           { value: 3, timestamp: (Time.zone.today - 2.days).in_time_zone('America/Sao_Paulo').to_i }
                         ]
                       when 'lost_deals_count'
                         [
                           { value: 4, timestamp: Time.zone.today.in_time_zone('America/Sao_Paulo').to_i }
                         ]
                       when 'open_deals_count'
                         [
                           { value: 2, timestamp: Time.zone.today.in_time_zone('America/Sao_Paulo').to_i },
                           { value: 1, timestamp: (Time.zone.today - 2.days).in_time_zone('America/Sao_Paulo').to_i }
                         ]
                       when 'all_deals_count'
                         [
                           { value: 11, timestamp: Time.zone.today.in_time_zone('America/Sao_Paulo').to_i },
                           { value: 4, timestamp: (Time.zone.today - 2.days).in_time_zone('America/Sao_Paulo').to_i }
                         ]
                       end

            expect(timeseries).to match_array(expected)
          end
        end
      end
    end
  end

  describe '#metric' do
    let(:params) { { metric: 'won_deals_count', id: stage.id, type: :stage } }

    it 'strips _count or _sum from metric' do
      instance = described_class.new(account, params)
      expect(instance.send(:metric)).to eq('won_deals')
    end

    it 'memoizes metric' do
      instance = described_class.new(account, params)
      expect(instance.send(:metric)).to eq('won_deals')
      instance.instance_variable_set(:@metric, 'other_metric')
      expect(instance.send(:metric)).to eq('other_metric')
    end
  end

  describe '#object_scope' do
    let(:params) do
      { metric:, id: stage.id, type: :stage, since: (Time.zone.today - 3.days).to_time.to_i.to_s,
        until: Time.zone.today.end_of_day.to_i.to_s }
    end

    %w[won_deals lost_deals open_deals all_deals].each do |metric|
      context "for #{metric}" do
        let(:metric) { "#{metric}_count" }

        it "returns correct scope for #{metric}" do
          instance = described_class.new(account, params)
          scope = instance.send(:object_scope)
          expect(scope).to be_a(ActiveRecord::Relation)
          case metric
          when 'won_deals'
            expect(scope.where_values_hash).to include('won_at' => instance.send(:range))
          when 'lost_deals'
            expect(scope.where_values_hash).to include('lost_at' => instance.send(:range))
          else
            expect(scope.where_values_hash).to include('created_at' => instance.send(:range))
          end
        end
      end
    end
  end

  describe '#grouping_field' do
    %w[won_deals lost_deals].each do |metric|
      it "returns #{metric == 'won_deals' ? :won_at : :lost_at} for #{metric}" do
        instance = described_class.new(account, metric:)
        expect(instance.send(:grouping_field)).to eq(metric == 'won_deals' ? :won_at : :lost_at)
      end
    end

    %w[open_deals all_deals].each do |metric|
      it 'returns :created_at for other metrics' do
        instance = described_class.new(account, metric:)
        expect(instance.send(:grouping_field)).to eq(:created_at)
      end
    end
  end
end
