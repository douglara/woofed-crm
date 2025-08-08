# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Accounts::Apps::AiAssistentsController, type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user) }
  let!(:ai_assistent) { create(:apps_ai_assistent) }
  let(:valid_params) do
    { apps_ai_assistent: { auto_reply: true, model: 'gpt-4', api_key: 'new_api_key', enabled: true } }
  end

  before do
    allow(Accounts::Create::EmbedCompanySiteJob).to receive(:perform_later)
  end

  describe 'GET /accounts/{account.id}/apps/ai_assistent/edit' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/apps/ai_assistent/edit"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      it 'renders edit page' do
        get "/accounts/#{account.id}/apps/ai_assistent/edit"
        expect(response).to have_http_status(:success)
        expect(response.body).to include(ai_assistent.api_key)
        expect(flash[:error]).to be_nil
      end
    end
  end

  describe 'PATCH /accounts/{account.id}/apps/ai_assistent' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch "/accounts/#{account.id}/apps/ai_assistent"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      context 'when update is successful' do
        let(:valid_params) do
          {
            account_id: account.id,
            apps_ai_assistent: {
              auto_reply: true,
              model: 'gpt-4',
              api_key: 'new_api_key',
              enabled: true
            }
          }
        end

        it 'updates the AI assistant and redirects to the edit page with a success notice' do
          patch "/accounts/#{account.id}/apps/ai_assistent", params: valid_params
          ai_assistent.reload

          expect(ai_assistent.auto_reply).to eq(true)
          expect(ai_assistent.model).to eq('gpt-4')
          expect(ai_assistent.api_key).to eq('new_api_key')
          expect(ai_assistent.enabled).to eq(true)
          expect(response).to redirect_to(edit_account_apps_ai_assistent_path(account))
          expect(flash[:notice]).to eq(I18n.t('flash_messages.updated', model: Apps::AiAssistent.model_name.human))
        end
      end

      context 'when update fails' do
        let(:invalid_params) do
          {
            apps_ai_assistent: {
              auto_reply: nil,
              model: '',
              api_key: '',
              enabled: nil
            }
          }
        end

        it 'invalid auto_reply value' do
          patch "/accounts/#{account.id}/apps/ai_assistent", params: invalid_params
          ai_assistent.reload

          expect(ai_assistent.auto_reply).not_to eq(nil)
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end
end
