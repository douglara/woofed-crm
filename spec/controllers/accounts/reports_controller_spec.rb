require 'rails_helper'

RSpec.describe Accounts::ReportsController, type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account:) }
  let!(:pipeline) { create(:pipeline, account:) }
  let(:starts_date) { Date.new(2025, 1, 1) }
  let(:ends_date) { Date.new(2025, 1, 31) }
  let(:date_range) { "#{starts_date.strftime('%d/%m/%Y')} - #{ends_date.strftime('%d/%m/%Y')}" }
  let(:valid_params) do
    {
      date_range:,
      metric: 'open_deals',
      group_by: 'day',
      timezone_offset: '-03:00',
      type: :account,
      filter: { users_id_eq: 'filter_test_123' }
    }
  end

  describe 'GET /accounts/{account.id}/reports' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/reports"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before { sign_in(user) }

      it 'renders the index page successfully' do
        get "/accounts/#{account.id}/reports"
        expect(response).to have_http_status(200)
        expect(response.body).to include('Reports')
        expect(response.body).to include(user.full_name)
      end
    end
  end

  describe 'GET /accounts/{account.id}/reports/summary' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/reports/summary"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before { sign_in(user) }

      context 'with valid parameters' do
        let(:summaries_data) do
          [
            { title: 'Open deals', amount_in_cents: 5000, quantity: 2 },
            { title: 'Created deals', amount_in_cents: 10_000, quantity: 4 },
            { title: 'Won deals', amount_in_cents: 2000, quantity: 1 },
            { title: 'Lost deals', amount_in_cents: 3000, quantity: 1 }
          ]
        end
        let(:timeseries_data) { [{ timestamp: 1.day.ago.to_i, value: 3 }] }

        before do
          allow(Reports::Deals::MetricBuilder).to receive(:new).and_return(
            double(summary: summaries_data.first)
          )
          allow(Reports::Deals::ReportBuilder).to receive(:new).and_return(
            double(timeseries: timeseries_data)
          )
        end

        it 'returns a successful response and assigns deal summary and timeseries' do
          get "/accounts/#{account.id}/reports/summary", params: valid_params
          expect(response).to have_http_status(200)

          doc = Nokogiri::HTML(response.body)
          summary_cards = doc.css('ul.grid > li.bg-light-palette-p5')

          expect(summary_cards.size).to eq(4)
          expect(summary_cards[0].css('h1').text).to include('Open deals')
          expect(summary_cards[0].css('span').attr('data-currency--format-exhibition-amount-in-cents-value').value)
            .to eq('5000')
          expect(summary_cards[0].css('span').text).to include(I18n.t('activerecord.models.deal.total_deals', count: 2))

          expect(response.body).to include(/data-controller='reports--chart'/)
          expect(response.body).to include('data-reports--chart-chart-data-value')
          expect(response.body).to include('#259C50')
          expect(response.body).to include('#CF4F27')
          expected_filter_query = { filter: valid_params[:filter] }.to_query
          expect(response.body).to include(expected_filter_query)
        end
      end

      context 'when date_range is not provided' do
        it 'sets date_range from since and until params' do
          params = valid_params.except(:date_range).merge(since: starts_date, until: ends_date)
          get("/accounts/#{account.id}/reports/summary", params:)
          expect(response).to have_http_status(200)
          expect(controller.params[:date_range]).to eq('2025-01-01 - 2025-01-31')
        end
      end
    end
  end

  describe 'GET /accounts/{account.id}/reports/pipeline_summary' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/reports/pipeline_summary"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before { sign_in(user) }

      context 'with valid pipeline_id and date_range' do
        let(:series_data) { { 'Stage 1' => 5, 'Stage 2' => 3 } }

        before do
          allow(Reports::Pipeline::StagesMetricBuilder).to receive(:new).and_return(
            double(metrics: series_data)
          )
        end

        it 'returns a successful response and renders pipeline summary' do
          get "/accounts/#{account.id}/reports/pipeline_summary",
              params: valid_params.merge(pipeline_id: pipeline.id, metric: 'won_deals')
          expect(response).to have_http_status(200)
          expect(response.body).to include(/data-controller='reports--chart'/)
          expect(response.body).to include(/turbo-frame id="pipeline_summary_reports"/)
          expect(response.body).to include('color-fg-feedback-success')
          expect(response.body).not_to include('color-fg-feedback-danger')
          expect(response.body).to include(valid_params[:filter][:users_id_eq])
        end
      end

      context 'when no pipeline exists' do
        before { Pipeline.delete_all }

        it 'returns a successful response with empty pipeline_summary' do
          get "/accounts/#{account.id}/reports/pipeline_summary", params: valid_params
          expect(response).to have_http_status(200)
          expect(response.body).to include('turbo-frame id="pipeline_summary_reports"')
        end
      end

      context 'when pipeline_id is invalid' do
        it 'returns 404 response with empty pipeline_summary' do
          get "/accounts/#{account.id}/reports/pipeline_summary", params: valid_params.merge(pipeline_id: 'invalid')
          expect(response).to have_http_status(404)
        end
      end
    end
  end
end
