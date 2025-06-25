require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe Accounts::EventsController, type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user) }
  let!(:contact) { create(:contact) }
  let!(:chatwoot) { create(:apps_chatwoots, :skip_validate) }
  let(:evolution_api_connected) { create(:apps_evolution_api, :connected) }
  let!(:pipeline) { create(:pipeline) }
  let!(:stage) { create(:stage, pipeline:) }
  let!(:deal) { create(:deal, contact:, stage:) }

  describe 'GET /accounts/{account.id}/events/calendar' do
    context 'when it is unthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/events/calendar"
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      it 'get event calendar page' do
        get "/accounts/#{account.id}/events/calendar"
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'GET /accounts/:account_id/events/calendar_events' do
    let(:params) {
        {
          start: '2025-06-20',
          end: '2025-06-30'
        }
      }
    context 'when it is unthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/events/calendar_events"
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      context 'returns the events within the date range as JSON' do
        let!(:event_wpp_message) do
          create(:event, account:, auto_done: false, additional_attributes: { message_id: 'id' }, scheduled_at: '2025-06-22',
                  kind: 'evolution_api_message', deal: deal)
        end
        let!(:event_chatwoot_message) do
          create(:event, account:, auto_done: false, additional_attributes: { message_id: 'id' }, scheduled_at: '2025-06-25',
                  kind: 'chatwoot_message', deal: deal)
        end
        let!(:event_activity) do
          create(:event, account:, scheduled_at: '2025-06-21',
                         kind: 'activity', deal: deal)
        end
        let!(:event_out_of_range) do
          create(:event, account:, scheduled_at: '2025-06-10',
                         kind: 'activity', deal: deal)
        end
        it do
          get("/accounts/#{account.id}/events/calendar_events", params:)

          expect(response).to have_http_status(:ok)

          json = JSON.parse(response.body)
          expect(json).to be_an(Array)
          expect(json.size).to eq(3)
          expect(json).not_to include(
            a_hash_including(
              'id' => event_out_of_range.id
            )
          )

          event_json = json.first

          expect(event_json['id']).to eq(event_activity.id)
          expect(event_json['title']).to eq(event_activity.title)
          expect(event_json['start']).to eq(event_activity.scheduled_at.iso8601)
          expect(event_json['backgroundColor']).to eq('#6857D9')
          expect(event_json['borderColor']).to eq('#6857D9')
          expect(event_json['extendedProps']['account_id']).to eq(account.id)
          expect(event_json['extendedProps']['contact_id']).to eq(event_activity.contact.id)
          expect(event_json['extendedProps']['deal_id']).to eq(event_activity.deal.id)
          expect(event_json['url']).to eq(Rails.application.routes.url_helpers.account_deal_path(account, event_activity.deal))
        end
      end
    end
  end
end
