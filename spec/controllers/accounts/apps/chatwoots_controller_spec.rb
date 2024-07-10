require 'rails_helper'
require 'webmock/rspec'

RSpec.describe Accounts::Apps::ChatwootsController, type: :request do
  let!(:account) { create(:account) }
  let(:chatwoot) { create(:apps_chatwoots, :skip_validate, account: account) }
  let!(:user) { create(:user, account: account) }
  let(:app_chatwoot_created) { Apps::Chatwoot.first }
  let(:dashboard_app_response) { File.read('spec/controllers/accounts/apps/dashboard_app_response.json') }
  let(:webhooks_response) { File.read('spec/controllers/accounts/apps/webhooks_response.json') }
  let(:inboxes_response) { File.read('spec/integration/use_cases/accounts/apps/chatwoots/inboxes.json') }
  let(:valid_params) do
    { apps_chatwoot: {
      chatwoot_endpoint_url: 'https://chatwoot.test.com/',
      chatwoot_account_id: '2',
      chatwoot_user_token: 'ASdasfdgfdgwEWWdfgfhgAWSDS'
    } }
  end
  let(:invalid_params) do
    { apps_chatwoot: {
      chatwoot_endpoint_url: 'invalid_url',
      chatwoot_account_id: '2',
      chatwoot_user_token: 'ASdasfdgfdgwEWWdfgfhgAWSDS'
    } }
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
    context 'when is unauthenticated user' do
      it 'returns unauthorized' do
        post "/accounts/#{account.id}/apps/chatwoots", params: valid_params
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    context 'when is authenticated user' do
      before do
        sign_in(user)
      end
      it 'create app chatwoots' do
        expect do
          post "/accounts/#{account.id}/apps/chatwoots", params: valid_params
        end.to change(Apps::Chatwoot, :count).by(1)
        expect(response).to have_http_status(302)
        expect(response).to redirect_to(edit_account_apps_chatwoot_path(account, app_chatwoot_created.id))
      end
      it 'create app chatwoots process failed' do
        expect do
          post "/accounts/#{account.id}/apps/chatwoots", params: invalid_params
        end.to change(Apps::Chatwoot, :count).by(0)
        expect(response).to have_http_status(200)
        expect(response.body).to include('Chatwoot URL Invalid chatwoot configuration')
      end
    end
  end
  describe 'GET /accounts/{account.id}/apps/chatwoots/new' do
    context 'when is unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/apps/chatwoots/new"
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    context 'when is authenticated user' do
      before do
        sign_in(user)
      end
      it 'should redirect to new apps chatwoots page' do
        get "/accounts/#{account.id}/apps/chatwoots/new"
        expect(response).to have_http_status(200)
      end
      context 'when apps chatwoots already exist' do
        it 'should redirect to edit page' do
          chatwoot
          get "/accounts/#{account.id}/apps/chatwoots/new"
          expect(response).to have_http_status(302)
          expect(response).to redirect_to(edit_account_apps_chatwoot_path(account, chatwoot))
        end
      end
    end
  end
  describe 'DELETE /accounts/{account.id}/apps/chatwoots/{chatwoot.id}' do
    before do
      stub_request(:delete, /dashboard_apps/)
        .to_return(body: '', status: 200, headers: { 'Content-Type' => 'application/json' })
      stub_request(:delete, /webhooks/)
        .to_return(body: '', status: 200, headers: { 'Content-Type' => 'application/json' })
    end
    context 'when is unauthenticated user' do
      it 'returns unautorized' do
        expect do
          delete "/accounts/#{account.id}/apps/chatwoots/#{chatwoot.id}"
        end.to change(Apps::Chatwoot, :count).by(1)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    context 'when is authenticated user' do
      before do
        sign_in(user)
      end
      it 'delete apps chatwoots' do
        expect do
          delete "/accounts/#{account.id}/apps/chatwoots/#{chatwoot.id}"
        end.to change(Apps::Chatwoot, :count).by(0)

        expect(response).to have_http_status(302)
        expect(response).to redirect_to(account_settings_path(account))
      end
    end
  end
  describe 'UPDATE /accounts/{account.id}/apps/chatwoots/{chatwoot.id}' do
    context 'when is unauthenticated user' do
      it 'returns unauthorized' do
        patch "/accounts/#{account.id}/apps/chatwoots/#{chatwoot.id}"
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    context 'when is authenticated user' do
      before do
        sign_in(user)
      end
      it 'delete apps chatwoots' do
        patch "/accounts/#{account.id}/apps/chatwoots/#{chatwoot.id}", params: valid_params
        expect(response).to have_http_status(302)
        expect(response).to redirect_to(edit_account_apps_chatwoot_path(account, chatwoot))
      end
    end
  end
end
