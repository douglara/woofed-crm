require 'rails_helper'
require 'webmock/rspec'

RSpec.describe Accounts::Apps::EvolutionApisController, type: :request do
  let!(:account) { create(:account) }
  let(:evolution_api) { create(:apps_evolution_api, account: account) }
  let!(:user) { create(:user, account: account) }
  let(:app_evolution_api_created) { Apps::EvolutionApi.first }
  let(:valid_params) do
    { apps_evolution_api: {
      name: 'woofed whatsapp'
    } }
  end
  let(:invalid_params) do
    { apps_evolution_api: {
      name: ''
    } }
  end

  describe 'POST /accounts/{account_id}/apps/evolution_apis' do
    let(:create_instance_response) do
      File.read('spec/integration/use_cases/accounts/apps/evolution_api/instance/create_response.json')
    end
    before do
      stub_request(:post, /instance/)
        .to_return(body: create_instance_response, status: 201, headers: { 'Content-Type' => 'application/json' })

      stub_request(:post, /settings/)
        .to_return(status: 200, body: '{"settings":{"instanceName":"3d3841c43940e8e60704","settings":{"reject_call":false,"groups_ignore":false,"always_online":false,"read_messages":false,"read_status":false}}}',
                   headers: { 'Content-Type' => 'application/json' })
    end
    context 'when is unauthenticated user' do
      it 'returns unauthorized' do
        post "/accounts/#{account.id}/apps/evolution_apis", params: valid_params
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    context 'when is authenticated user' do
      before do
        sign_in(user)
      end
      it 'create app evolution_apis' do
        expect do
          post "/accounts/#{account.id}/apps/evolution_apis", params: valid_params
        end.to change(Apps::EvolutionApi, :count).by(1)
        expect(response).to have_http_status(302)
        expect(response).to redirect_to(pair_qr_code_account_apps_evolution_api_path(app_evolution_api_created.account,
                                                                                     app_evolution_api_created.id))
      end
      it 'create app evolution_apis process failed' do
        expect do
          post "/accounts/#{account.id}/apps/evolution_apis", params: invalid_params
        end.to change(Apps::EvolutionApi, :count).by(0)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to match(/Name can&#39;t be blank/)
      end
    end
  end
  describe 'GET /accounts/{account_id}/apps/evolution_apis/new' do
    context 'when is unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/apps/evolution_apis/new"
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    context 'when is authenticated user' do
      before do
        sign_in(user)
      end
      it 'should redirect to new apps evolution_apis page' do
        get "/accounts/#{account.id}/apps/evolution_apis/new"
        expect(response).to have_http_status(200)
        expect(response.body).to include('Connection data')
      end
    end
  end

  describe 'UPDATE /accounts/{account_id}/apps/evolution_apis/{evolution_api_id}' do
    context 'when is unauthenticated user' do
      it 'returns unauthorized' do
        patch "/accounts/#{account.id}/apps/evolution_apis/#{evolution_api.id}"
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    context 'when is authenticated user' do
      before do
        sign_in(user)
      end
      it 'update apps evoluiton_apis' do
        patch "/accounts/#{account.id}/apps/evolution_apis/#{evolution_api.id}", params: valid_params
        expect(response).to have_http_status(302)
        expect(response).to redirect_to(edit_account_apps_evolution_api_path(account, evolution_api))
        expect(flash[:notice]).to eq('Whatsapp was successfully updated.')
      end
      context 'when update with invalid params' do
        it 'should not update' do
          patch "/accounts/#{account.id}/apps/evolution_apis/#{evolution_api.id}", params: invalid_params
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to match(/Name can&#39;t be blank/)
        end
      end
    end
  end

  describe 'GET /accounts/{account_id}/apps/evolution_apis/{evolution_api_id}/edit' do
    context 'when is unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/apps/evolution_apis/#{evolution_api.id}/edit"
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    context 'when is authenticated user' do
      before do
        sign_in(user)
      end
      it 'should redirect to edit evolution_apis page' do
        get "/accounts/#{account.id}/apps/evolution_apis/#{evolution_api.id}/edit"
        expect(response).to have_http_status(200)
        expect(response.body).to include('Connection data')
      end
    end
  end

  describe 'GET /accounts/{account_id}/apps/evolution_apis' do
    context 'when is unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/apps/evolution_apis"
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    context 'when is authenticated user' do
      before do
        sign_in(user)
      end
      context 'when there are evolution_api disconnected and connecting' do
        let!(:evolution_api) { create(:apps_evolution_api, account: account) }
        let!(:evolution_api_connecting) { create(:apps_evolution_api, :connecting, account: account) }
        it 'should show connect button link' do
          get "/accounts/#{account.id}/apps/evolution_apis"
          expect(response).to have_http_status(200)
          expect(response.body).to include(pair_qr_code_account_apps_evolution_api_path(account, evolution_api))
          expect(response.body).to include(pair_qr_code_account_apps_evolution_api_path(account,
                                                                                        evolution_api_connecting))
        end
      end
      context 'when there is evolution_api connected' do
        let!(:evolution_api_connected) { create(:apps_evolution_api, :connected, account: account) }
        it 'should not show connect button link' do
          get "/accounts/#{account.id}/apps/evolution_apis"
          expect(response).to have_http_status(200)
          expect(response.body).not_to include(pair_qr_code_account_apps_evolution_api_path(account,
                                                                                            evolution_api_connected))
        end
      end
    end
  end

  describe 'GET /accounts/{account_id}/apps/evolution_apis/{evolution_api_id}/pair_qr_code' do
    context 'when is unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/apps/evolution_apis/#{evolution_api.id}/pair_qr_code"
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    context 'when is authenticated user' do
      let!(:evolution_api_connecting) { create(:apps_evolution_api, :connecting, account: account) }
      before do
        sign_in(user)
      end
      context 'when evolution_api is connecting' do
        it 'should show qrcode' do
          get "/accounts/#{account.id}/apps/evolution_apis/#{evolution_api_connecting.id}/pair_qr_code"
          expect(response).to have_http_status(200)
          expect(response.body).to include('qrcode_connecting')
        end
      end
      context 'when evolution_api is disconnected' do
        it 'should show qrcode refresh link' do
          get "/accounts/#{account.id}/apps/evolution_apis/#{evolution_api.id}/pair_qr_code"
          expect(response).to have_http_status(200)
          expect(response.body).to include('Click here to load the QR code')
        end
      end
      context 'when evolution_api is connected' do
        let!(:evolution_api_connected) { create(:apps_evolution_api, :connected, account: account) }
        it 'should not show qrcode' do
          get "/accounts/#{account.id}/apps/evolution_apis/#{evolution_api_connected.id}/pair_qr_code"
          expect(response).to have_http_status(200)
          expect(response.body).to include('<img src="" alt="" class="mx-auto lg:m-0">')
        end
      end
    end
  end

  describe 'POST /accounts/{account_id}/apps/evolution_apis/{evolution_api_id}/refresh_qr_code' do
    let(:create_instance_response) do
      File.read('spec/integration/use_cases/accounts/apps/evolution_api/instance/create_response.json')
    end
    before do
      stub_request(:post, /instance/)
        .to_return(body: create_instance_response, status: 201, headers: { 'Content-Type' => 'application/json' })
      stub_request(:post, /settings/)
        .to_return(status: 201, body: '{"settings":{"instanceName":"3d3841c43940e8e60704","settings":{"reject_call":false,"groups_ignore":false,"always_online":false,"read_messages":false,"read_status":false}}}',
                   headers: { 'Content-Type' => 'application/json' })
    end
    context 'when is unauthenticated user' do
      it 'returns unauthorized' do
        post "/accounts/#{account.id}/apps/evolution_apis/#{evolution_api.id}/refresh_qr_code"
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    context 'when is authenticated user' do
      before do
        sign_in(user)
      end
      it do
        expect do
          post "/accounts/#{account.id}/apps/evolution_apis/#{evolution_api.id}/refresh_qr_code"
        end.to change(Apps::EvolutionApi, :count).by(1)
        expect(response).to have_http_status(204)
      end
    end
  end
  describe 'DELETE /accounts/{account_id}/apps/evolution_apis/{evolution_api_id}' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/accounts/#{account.id}/apps/evolution_apis/#{evolution_api.id}"
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end
      context 'delete the user' do
        it do
          delete "/accounts/#{account.id}/apps/evolution_apis/#{evolution_api.id}"
          expect(Apps::EvolutionApi.count).to eq(0)
          expect(response.status).to eq(302)
          expect(flash[:notice]).to include('Whatsapp was successfully destroyed.')
        end
      end
    end
  end
end
