require 'rails_helper'

RSpec.describe Accounts::Settings::Deals::DealLostReasonsController, type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user) }
  let(:last_deal_lost_reason) { DealLostReason.last }

  describe 'GET /accounts/:account_id/settings/deals/deal_lost_reasons' do
    context 'when unauthenticated' do
      it 'redirects to login' do
        get "/accounts/#{account.id}/settings/deals/deal_lost_reasons"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before { sign_in(user) }
      let!(:deal_lost_reason) { create(:deal_lost_reason) }

      it 'returns list of deal lost reasons and display Allow free-form reasons toggle form' do
        get "/accounts/#{account.id}/settings/deals/deal_lost_reasons"
        expect(response).to have_http_status(:success)
        expect(response.body).to include(deal_lost_reason.name)
        expect(response.body).to include(I18n.t('activerecord.attributes.account.deal_free_form_lost_reasons'))
      end

      context 'when there is no deal_lost_reason' do
        before do
          DealLostReason.destroy_all
        end

        it 'does not display the Allow free-form reasons toggle form' do
          get "/accounts/#{account.id}/settings/deals/deal_lost_reasons"
          expect(response).to have_http_status(:success)
          expect(response.body).not_to include(I18n.t('activerecord.attributes.account.deal_free_form_lost_reasons'))
        end
      end
    end
  end

  describe 'GET /accounts/:account_id/settings/deals/deal_lost_reasons/new' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/settings/deals/deal_lost_reasons/new"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before { sign_in(user) }

      it 'renders new page' do
        get "/accounts/#{account.id}/settings/deals/deal_lost_reasons/new"
        expect(response).to have_http_status(:success)
        expect(response.body).to include('New lost reason')
      end
    end
  end

  describe 'GET /accounts/:account_id/settings/deals/deal_lost_reasons/:id/edit' do
    let!(:deal_lost_reason) { create(:deal_lost_reason) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/settings/deals/deal_lost_reasons/#{deal_lost_reason.id}/edit"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before { sign_in(user) }

      it 'renders edit page' do
        get "/accounts/#{account.id}/settings/deals/deal_lost_reasons/#{deal_lost_reason.id}/edit"
        expect(response).to have_http_status(:success)
        expect(response.body).to include(ERB::Util.html_escape(deal_lost_reason.name))
      end
    end
  end

  describe 'POST /accounts/:account_id/settings/deals/deal_lost_reasons' do
    let!(:deal_lost_reason) { create(:deal_lost_reason) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/accounts/#{account.id}/settings/deals/deal_lost_reasons", params: {}
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before { sign_in(user) }
      let(:params) { { deal_lost_reason: { name: } } }

      context 'with valid params' do
        let(:name) { 'New reason' }

        it 'creates a deal lost reason' do
          expect do
            post "/accounts/#{account.id}/settings/deals/deal_lost_reasons", params:
          end.to change(DealLostReason, :count).by(1)

          expect(response).to redirect_to("/accounts/#{account.id}/settings/deals/deal_lost_reasons")
          expect(flash[:notice]).to eq(I18n.t('flash_messages.created', model: DealLostReason.model_name.human))
          expect(last_deal_lost_reason.name).to eq('New reason')
        end
      end

      context 'with invalid params' do
        let(:name) { '' }

        it 'does not create and returns unprocessable_entity' do
          expect do
            post "/accounts/#{account.id}/settings/deals/deal_lost_reasons", params:
          end.to change(DealLostReason, :count).by(0)

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to match(/lost reason can&#39;t be blank/)
        end
      end
    end
  end

  describe 'PATCH /accounts/:account_id/settings/deals/deal_lost_reasons/:id' do
    let!(:deal_lost_reason) { create(:deal_lost_reason) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch "/accounts/#{account.id}/settings/deals/deal_lost_reasons/#{deal_lost_reason.id}", params: {}
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before { sign_in(user) }
      let(:params) { { deal_lost_reason: { name: } } }

      context 'with valid params' do
        let(:name) { 'Updated test reason' }

        it 'updates the deal lost reason' do
          patch("/accounts/#{account.id}/settings/deals/deal_lost_reasons/#{deal_lost_reason.id}",
                params:)

          expect(deal_lost_reason.reload.name).to eq('Updated test reason')
          expect(response).to redirect_to("/accounts/#{account.id}/settings/deals/deal_lost_reasons/#{deal_lost_reason.id}/edit")
          expect(flash[:notice]).to eq(I18n.t('flash_messages.updated', model: DealLostReason.model_name.human))
        end
      end

      context 'with invalid params' do
        let(:name) { '' }

        it 'does not update and returns unprocessable_entity' do
          patch("/accounts/#{account.id}/settings/deals/deal_lost_reasons/#{deal_lost_reason.id}",
                params:)

          expect(deal_lost_reason.reload.name).not_to eq('')
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to match(/lost reason can&#39;t be blank/)
        end
      end
    end
  end

  describe 'DELETE /accounts/:account_id/settings/deals/deal_lost_reasons/:id' do
    let!(:deal_lost_reason) { create(:deal_lost_reason) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/accounts/#{account.id}/settings/deals/deal_lost_reasons/#{deal_lost_reason.id}"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before { sign_in(user) }

      it 'deletes the deal lost reason' do
        deal_lost_reason_to_delete = create(:deal_lost_reason)
        expect do
          delete "/accounts/#{account.id}/settings/deals/deal_lost_reasons/#{deal_lost_reason.id}"
        end.to change(DealLostReason, :count).by(-1)

        expect(response).to redirect_to("/accounts/#{account.id}/settings/deals/deal_lost_reasons")
        expect(flash[:notice]).to eq(I18n.t('flash_messages.deleted', model: DealLostReason.model_name.human))
      end
    end
  end
end
