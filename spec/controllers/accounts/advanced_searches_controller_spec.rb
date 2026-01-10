require 'rails_helper'

RSpec.describe Accounts::AdvancedSearchesController, type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user) }
  let(:params) { { q: 'Test search query', search_type: 'all' } }

  describe 'GET /accounts/{account.id}/advanced_search' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get("/accounts/#{account.id}/advanced_search", params:)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      it 'returns advanced searches page' do
        get("/accounts/#{account.id}/advanced_search", params:)
        expect(response).to have_http_status(:success)
        expect(response.body).to include('results_session')
        expect(response.body).to include(params[:q])
        expect(response.body).to include(params[:search_type])
      end
    end
  end

  describe 'GET /accounts/{account.id}/advanced_search/results' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get("/accounts/#{account.id}/advanced_search/results", params:)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      context 'when there is results' do
        let!(:contact) do
          create(:contact, full_name: 'Test search query', phone: '+55229988655', email: 'john@email.com')
        end
        let!(:stage) { create(:stage, name: 'Test search query') }
        let!(:deal) { create(:deal, name: 'Test search query', stage:) }
        let!(:pipeline) { create(:pipeline, name: 'Test search query') }
        let!(:product) { create(:product, name: 'Test search query', identifier: 'PROD-001') }
        let!(:activity) do
          create(:event, deal:, title: 'Test search query',
                         scheduled_at: Time.zone.parse('2025-01-15 10:30:00'), kind: 'activity')
        end

        it 'returns search results page' do
          get("/accounts/#{account.id}/advanced_search/results", params:)
          expect(response).to have_http_status(:success)
          expect(response.body).to include('results')
          expect(response.body).to include(params[:q])
          expect(response.body).to include(params[:search_type])
          expect(response.body).to include(contact.full_name)
          expect(response.body).to include(contact.email)
          expect(response.body).to include(contact.phone)
          expect(response.body).to include(deal.name)
          expect(response.body).to include(stage.name)
          expect(response.body).to include(product.name)
          expect(response.body).to include(product.identifier)
          expect(response.body).to include(pipeline.name)
          expect(response.body).to include(activity.title)
          expect(response.body).to include(activity.scheduled_at.to_s)
          expect(response.body).not_to include(I18n.t('views.accounts.advanced_searches.no_results'))
        end
      end

      context 'when there is no results' do
        let(:params) { { q: 'Nonexistent query', search_type: 'all' } }

        it 'returns no results' do
          get("/accounts/#{account.id}/advanced_search/results", params:)
          expect(response).to have_http_status(:success)
          expect(response.body).to include('results')
          expect(response.body).to include(I18n.t('views.accounts.advanced_searches.no_results'))
        end
      end
    end
  end
end
