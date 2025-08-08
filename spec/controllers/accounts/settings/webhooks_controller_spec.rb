require 'rails_helper'

RSpec.describe Accounts::Settings::WebhooksController, type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user) }
  let!(:webhook) { create(:webhook, :skip_validate, url: 'https://woofedcrm.com') }
  let(:valid_params) { { webhook: { url: 'https://testeurl.com.br', status: 'active' } } }

  describe 'GET /accounts/{account.id}/webhooks' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/webhooks"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      it 'gets webhooks by account' do
        get "/accounts/#{account.id}/webhooks"
        expect(response.body).to include(webhook.url)
        expect(response).to have_http_status(:success)
        expect(flash[:error]).to be_nil
      end
    end
  end

  describe 'GET /accounts/{account.id}/webhooks/new' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/webhooks/new"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      it 'renders new page' do
        get "/accounts/#{account.id}/webhooks/new"
        expect(response).to have_http_status(:success)
        expect(response.body).to include('Create Webhook')
        expect(flash[:error]).to be_nil
      end
    end
  end

  describe 'GET /accounts/{account.id}/webhooks/{webhook.id}/edit' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/webhooks/#{webhook.id}/edit"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      it 'renders edit page' do
        get "/accounts/#{account.id}/webhooks/#{webhook.id}/edit"
        expect(response).to have_http_status(:success)
        expect(response.body).to include(ERB::Util.html_escape(webhook.url))
        expect(flash[:error]).to be_nil
      end
    end
  end

  describe 'POST /accounts/{account.id}/webhooks' do
    before do
      stub_request(:post, 'https://testeurl.com.br').to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/accounts/#{account.id}/webhooks"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      it 'creates webhook successfully' do
        expect do
          post "/accounts/#{account.id}/webhooks", params: valid_params
        end.to change(Webhook, :count).by(1)
        expect(response).to redirect_to(account_webhooks_path(account))
        expect(flash[:error]).to be_nil
      end

      context 'when params invalid' do
        it 'should return unprocessable_entity' do
          invalid_params = { webhook: { url: '' } }
          expect do
            post "/accounts/#{account.id}/webhooks",
                  params: invalid_params
          end.to change(Webhook, :count).by(0)
          expect(response.body).to match(/URL can&#39;t be blank/)
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  describe 'PATCH /accounts/{account.id}/webhooks/{webhook.id}' do
    before do
      stub_request(:post, 'https://www.url-updated.com.br').to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })
    end

    let(:valid_params) { { webhook: { url: 'https://www.url-updated.com.br' } } }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch "/accounts/#{account.id}/webhooks/#{webhook.id}"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      it 'updates webhook successfully' do
        patch "/accounts/#{account.id}/webhooks/#{webhook.id}", params: valid_params
        expect(webhook.reload.url).to eq('https://www.url-updated.com.br')
        expect(response).to redirect_to(edit_account_webhook_path(account, webhook))
        expect(flash[:error]).to be_nil
      end

      context 'when params is invalid' do
        it 'should return unprocessable_entity' do
          invalid_params = { webhook: { url: '' } }

          patch "/accounts/#{account.id}/webhooks/#{webhook.id}",
                params: invalid_params
          expect(webhook.reload.url).to eq('https://woofedcrm.com')
          expect(response.body).to match(/URL can&#39;t be blank/)
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  describe 'DELETE /accounts/{account.id}/webhooks/{webhook.id}' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/accounts/#{account.id}/webhooks/#{webhook.id}"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      it 'deletes webhook successfully' do
        expect do
          delete "/accounts/#{account.id}/webhooks/#{webhook.id}"
        end.to change(Webhook, :count).by(-1)
        expect(response).to have_http_status(:no_content)
        expect(flash[:error]).to be_nil
      end
    end
  end
end
