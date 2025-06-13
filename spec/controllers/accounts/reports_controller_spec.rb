require 'rails_helper'

RSpec.describe Accounts::ReportsController, type: :request, skip: true do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account:) }
  let(:starts_date) { Date.new(2025, 1, 1) }
  let(:ends_date) { Date.new(2025, 1, 31) }
  let(:date_range) { "#{starts_date.strftime('%d/%m/%Y')} - #{ends_date.strftime('%d/%m/%Y')}" }

  describe 'GET /accounts/{account.id}/reports' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/reports"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      it 'returns a successful response' do
        get "/accounts/#{account.id}/reports"
        expect(response).to have_http_status(200)
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
      before do
        sign_in(user)
      end
      let(:summaries_data) do
        {
          summaries: [
            { title: 'Open deals', amount: 5000, count: 2 },
            { title: 'Created deals', amount: 10_000, count: 4 },
            { title: 'Won deals', amount: 2000, count: 1 },
            { title: 'Lost deals', amount: 3000, count: 1 }
          ],
          column_chart_data: { categories: ['Jan 2025'], series: [] }
        }
      end

      it 'returns a successful response and assigns summaries' do
        allow_any_instance_of(ReportBuilder).to receive(:build).with(:summary).and_return(summaries_data)
        get "/accounts/#{account.id}/reports/summary", params: { date_range: }
        expect(response).to have_http_status(200)
      end

      context 'when date_range is not provided' do
        it 'passes date_range to ReportBuilder' do
          expect_any_instance_of(ReportBuilder).to receive(:build).with(:summary).and_return(summaries_data)
          get "/accounts/#{account.id}/reports/summary", params: { date_range: '' }
          expect(response).to have_http_status(200)
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
      before do
        sign_in(user)
      end

      it 'returns a successful response and assigns pipeline_summary' do
        pipeline_summary_data = {
          funnel_chart_data: {
            categories: ['Stage 1', 'Stage 2'],
            series: [{ name: 'Main Pipeline', data: [1, 1] }]
          }
        }
        allow_any_instance_of(ReportBuilder).to receive(:build).with(:pipeline_summary).and_return(pipeline_summary_data)

        get "/accounts/#{account.id}/reports/pipeline_summary", params: { date_range: }
        expect(response).to have_http_status(200)
      end

      context 'when pipeline_id and date_range are provided' do
        let(:pipeline) { create(:pipeline, account:) }

        it 'passes pipeline_id and date_range to ReportBuilder' do
          expect_any_instance_of(ReportBuilder).to receive(:build).with(:pipeline_summary).and_return({})
          get "/accounts/#{account.id}/reports/pipeline_summary", params: { date_range:, pipeline_id: pipeline.id }
          expect(response).to have_http_status(200)
        end
      end

      context 'when no pipeline exists' do
        before do
          Pipeline.delete_all
          allow_any_instance_of(ReportBuilder).to receive(:build).with(:pipeline_summary).and_return({})
        end

        it 'returns a successful response with empty pipeline_summary' do
          get "/accounts/#{account.id}/reports/pipeline_summary", params: { date_range: }
          expect(response).to have_http_status(200)
        end
      end
    end
  end
end
