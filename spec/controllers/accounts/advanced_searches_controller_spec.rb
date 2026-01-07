require 'rails_helper'

RSpec.describe Accounts::AdvancedSearchesController, type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user) }
  let(:params) { { q: 'John Doe', search_type: 'contacts' } }
  let(:result_mock) do
    { contacts: [instance_double(Contact, full_name: 'John Doe', phone: '+55229988655', email: 'mario@email.com')] }
  end

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

      context 'returns search results page' do
        it do
          allow(Query::AdvancedSearch).to receive(:new).with(user, user.account,
                                                             instance_of(ActionController::Parameters)).and_return(instance_double(
                                                                                                                     Query::AdvancedSearch, call: result_mock
                                                                                                                   ))

          get("/accounts/#{account.id}/advanced_searches/search_results", params:)
          expect(response).to have_http_status(:success)
          expect(response.body).to include('search_results')
          expect(response.body).to include(params[:q])
          expect(response.body).to include(params[:search_type])
        end
      end

      context 'when no results are found' do
        it 'returns no results' do
          allow(Query::AdvancedSearch).to receive(:new).with(user, user.account,
                                                             instance_of(ActionController::Parameters)).and_return(instance_double(
                                                                                                                     Query::AdvancedSearch, call: {}
                                                                                                                   ))

          get("/accounts/#{account.id}/advanced_searches/search_results", params:)
          expect(response).to have_http_status(:success)
          expect(response.body).to include('search_results')
          expect(response.body).to include(I18n.t('views.accounts.advanced_searches.no_results'))
        end
      end
    end
  end
end
