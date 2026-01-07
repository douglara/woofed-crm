require 'rails_helper'

RSpec.describe Accounts::AdvancedSearchesController, type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user) }
  let(:params) { { q: 'John Doe', search_type: 'contacts' } }

  describe 'GET /accounts/{account.id}/advanced_searches' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get("/accounts/#{account.id}/advanced_searches", params:)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      it 'returns advanced searches page' do
        get("/accounts/#{account.id}/advanced_searches", params:)
        expect(response).to have_http_status(:success)
        expect(response.body).to include('search_results_session')
        expect(response.body).to include(params[:q])
        expect(response.body).to include(params[:search_type])
      end
    end
  end

  describe 'GET /accounts/{account.id}/advanced_searches/search_results' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get("/accounts/#{account.id}/advanced_searches/search_results", params:)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      before do
        allow(Query::AdvancedSearch).to receive(:new)
          .with(
            user,
            user.account,
            ActionController::Parameters.new(params).permit(:q, :search_type)
          )
          .and_return(
            instance_double(Query::AdvancedSearch, call: result_mock)
          )
      end

      context 'when there is results' do
        let(:contact_mock) do
          instance_double(Contact, full_name: 'John Doe', phone: '+55229988655', email: 'john@email.com')
        end
        let(:stage_mock) { instance_double(Stage, name: 'Stage 1') }
        let(:deal_mock) { instance_double(Deal, name: 'Big Deal', stage: stage_mock) }
        let(:pipeline_mock) { instance_double(Pipeline, name: 'Sales Pipeline') }
        let(:product_mock) { instance_double(Product, name: 'Product A', identifier: 'PROD-001') }
        let(:activity_mock) do
          instance_double(Event, deal: deal_mock, title: 'Activity A',
                                 scheduled_at: Time.zone.parse('2025-01-15 10:30:00'))
        end
        let(:result_mock) do
          { contacts: [contact_mock],
            deals: [deal_mock],
            pipelines: [pipeline_mock],
            products: [product_mock],
            activities: [activity_mock] }
        end

        it 'returns search results page with results' do
          get("/accounts/#{account.id}/advanced_searches/search_results", params:)
          expect(response).to have_http_status(:success)
          expect(response.body).to include('search_results')
          expect(response.body).to include(params[:q])
          expect(response.body).to include(params[:search_type])
          expect(response.body).to include(contact_mock.full_name)
          expect(response.body).to include(contact_mock.email)
          expect(response.body).to include(contact_mock.phone)
          expect(response.body).to include(deal_mock.name)
          expect(response.body).to include(stage_mock.name)
          expect(response.body).to include(product_mock.name)
          expect(response.body).to include(product_mock.identifier)
          expect(response.body).to include(pipeline_mock.name)
          expect(response.body).to include(activity_mock.title)
          expect(response.body).to include(activity_mock.scheduled_at.to_s)
          expect(response.body).not_to include(I18n.t('views.accounts.advanced_searches.no_results'))
        end
      end

      context 'when there is no results' do
        let(:result_mock) { {} }

        it 'returns no results' do
          get("/accounts/#{account.id}/advanced_searches/search_results", params:)
          expect(response).to have_http_status(:success)
          expect(response.body).to include('search_results')
          expect(response.body).to include(I18n.t('views.accounts.advanced_searches.no_results'))
        end
      end
    end
  end
end
