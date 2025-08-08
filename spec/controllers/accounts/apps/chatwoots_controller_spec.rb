require 'rails_helper'
require 'webmock/rspec'

RSpec.describe Accounts::Apps::ChatwootsController, type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account:) }
  let(:chatwoot) { create(:apps_chatwoots, :skip_validate, account:) }
  let(:valid_params) do
    { apps_chatwoot: { chatwoot_endpoint_url: 'https://chatwoot.test.com/', chatwoot_account_id: '2', chatwoot_user_token: 'ASdasfdgfdgwEWWdfgfhgAWSDS' } }
  end
  let(:invalid_params) do
    { apps_chatwoot: {
      chatwoot_endpoint_url: 'invalid_url',
      chatwoot_account_id: '2',
      chatwoot_user_token: 'ASdasfdgfdgwEWWdfgfhgAWSDS'
    } }
  end
  let(:dashboard_app_response) { File.read('spec/controllers/accounts/apps/dashboard_app_response.json') }
  let(:webhooks_response) { File.read('spec/controllers/accounts/apps/webhooks_response.json') }
  let(:inboxes_response) { File.read('spec/integration/use_cases/accounts/apps/chatwoots/inboxes.json') }

  describe 'GET /accounts/{account.id}/apps/chatwoots/new' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/apps/chatwoots/new"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      it 'renders new page when no chatwoot exists' do
        get "/accounts/#{account.id}/apps/chatwoots/new"
        expect(response).to have_http_status(:success)
        expect(response.body).to include('Configure Chatwoot')
        expect(flash[:error]).to be_nil
      end

      context 'when chatwoot exists' do
        it 'redirects to edit page' do
          chatwoot
          get "/accounts/#{account.id}/apps/chatwoots/new"
          expect(response).to redirect_to(edit_account_apps_chatwoot_path(account, chatwoot))
          expect(flash[:error]).to be_nil
        end
      end
    end
  end

  describe 'GET /accounts/{account.id}/apps/chatwoots/{chatwoot.id}/edit' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/apps/chatwoots/#{chatwoot.id}/edit"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      it 'renders edit page' do
        get "/accounts/#{account.id}/apps/chatwoots/#{chatwoot.id}/edit"
        expect(response).to have_http_status(:success)
        expect(response.body).to include(ERB::Util.html_escape(chatwoot.chatwoot_endpoint_url))
        expect(flash[:error]).to be_nil
      end
    end
  end

  describe 'POST /accounts/{account.id}/apps/chatwoots' do
    before do
      stub_request(:post, /dashboard_apps/)
        .to_return(body: dashboard_app_response, status: 200, headers: { 'Content-Type' => 'application/json' })
      stub_request(:post, /webhooks/)
        .to_return(body: webhooks_response, status: 200, headers: { 'Content-Type' => 'application/json' })
      stub_request(:get, /inboxes/)
        .to_return(body: inboxes_response, status: 200, headers: { 'Content-Type' => 'application/json' })
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/accounts/#{account.id}/apps/chatwoots", params: valid_params
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      let(:profile_response) do
        File.read('spec/fixtures/models/apps/chatwoot/api_client/profile_administrator_request.json')
      end
      let(:request_headers) { { 'Content-Type' => 'application/json' } }

      before do
        sign_in(user)
        stub_request(:get, %r{api/v1/profile})
          .to_return(status: 200, body: profile_response, headers: { 'Content-Type' => 'application/json' })
      end

      it 'creates chatwoot successfully' do
        expect do
          post "/accounts/#{account.id}/apps/chatwoots", params: valid_params
        end.to change(Apps::Chatwoot, :count).by(1)
        expect(response).to redirect_to(edit_account_apps_chatwoot_path(account, Apps::Chatwoot.first))
        expect(flash[:error]).to be_nil
      end
      it 'create app chatwoots process failed' do
        expect do
          post "/accounts/#{account.id}/apps/chatwoots", params: invalid_params
        end.to change(Apps::Chatwoot, :count).by(0)
        expect(response).to have_http_status(200)
        expect(response.body).to include('Chatwoot user token is invalid')
      end
    end
  end

  describe 'PATCH /accounts/{account.id}/apps/chatwoots/{chatwoot.id}' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch "/accounts/#{account.id}/apps/chatwoots/#{chatwoot.id}"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      it 'updates chatwoot successfully' do
        patch "/accounts/#{account.id}/apps/chatwoots/#{chatwoot.id}", params: valid_params
        expect(response).to redirect_to(edit_account_apps_chatwoot_path(account, chatwoot))
        expect(flash[:error]).to be_nil
      end
    end
  end

  describe 'DELETE /accounts/{account.id}/apps/chatwoots/{chatwoot.id}' do
    let!(:chatwoot) { create(:apps_chatwoots, :skip_validate, account:) }

    before do
      stub_request(:delete, /dashboard_apps/).to_return(status: 200, body: '', headers: { 'Content-Type' => 'application/json' })
      stub_request(:delete, /webhooks/).to_return(status: 200, body: '', headers: { 'Content-Type' => 'application/json' })
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/accounts/#{account.id}/apps/chatwoots/#{chatwoot.id}"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      it 'deletes chatwoot successfully' do
        expect do
          delete "/accounts/#{account.id}/apps/chatwoots/#{chatwoot.id}"
        end.to change(Apps::Chatwoot, :count).by(-1)
        expect(response).to redirect_to(account_settings_path(account))
        expect(flash[:error]).to be_nil
      end
    end
  end
end
