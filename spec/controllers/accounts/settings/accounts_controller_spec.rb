require 'rails_helper'

RSpec.describe Accounts::Settings::AccountsController, type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user) }

  describe 'GET /accounts/{account.id}/settings/account/edit' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/settings/account/edit"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      it 'renders edit page' do
        get "/accounts/#{account.id}/settings/account/edit"
        expect(response).to have_http_status(:success)
        expect(response.body).to include(ERB::Util.html_escape(account.name))
        expect(response.body).to include(account.currency_code)
        expect(response.body).to include(account.site_url)
        expect(response.body).to include(account.segment)
        expect(response.body).to include(account.number_of_employees)
      end
    end
  end

  describe 'PATCH /accounts/{account.id}/settings/account' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch "/accounts/#{account.id}/settings/account"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      let!(:deal_lost_reason) { create(:deal_lost_reason) }

      let(:params) do
        { account: { name: 'Company WoofedCRM', currency_code: 'USD', segment: 'education', site_url: 'https://woofedcrm.com', number_of_employees: '51-200', deal_free_form_lost_reasons: true, deal_allow_edit_lost_at_won_at: true } }
      end

      before do
        sign_in(user)
      end

      it 'updates account successfully' do
        patch("/accounts/#{account.id}/settings/account", params:)
        expect(response).to redirect_to(edit_account_settings_account_path(account))
        expect(flash[:notice]).to eq(I18n.t('flash_messages.updated', model: Account.model_name.human))
        expect(account.reload.name).to eq('Company WoofedCRM')
        expect(account.currency_code).to eq('USD')
        expect(account.segment).to eq('education')
        expect(account.site_url).to eq('https://woofedcrm.com')
        expect(account.number_of_employees).to eq('51-200')
        expect(account.deal_free_form_lost_reasons).to eq(true)
        expect(account.deal_allow_edit_lost_at_won_at).to eq(true)
      end

      context 'when params is invalid' do
        it 'should return unprocessable_entity' do
          params = { account: { currency_code: 'xpto' } }

          patch("/accounts/#{account.id}/settings/account", params:)
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to match(I18n.t('errors.messages.inclusion'))
        end
      end
    end
  end
end
