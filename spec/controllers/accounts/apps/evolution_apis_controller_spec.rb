require 'rails_helper'
require 'webmock/rspec'

RSpec.describe Accounts::Apps::EvolutionApisController, type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user) }
  let!(:evolution_api) { create(:apps_evolution_api) }
  let(:valid_params) { { apps_evolution_api: { name: 'woofed whatsapp' } } }
  let(:invalid_params) do
    { apps_evolution_api: {
      name: ''
    } }
  end

  describe 'GET /accounts/{account.id}/apps/evolution_apis' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/apps/evolution_apis"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      it 'shows evolution APIs' do
        get "/accounts/#{account.id}/apps/evolution_apis"
        expect(response).to have_http_status(:success)
        expect(flash[:error]).to be_nil
      end
      context 'when there are evolution_api disconnected and connecting' do
        let!(:evolution_api) { create(:apps_evolution_api) }
        let!(:evolution_api_connecting) { create(:apps_evolution_api, :connecting) }
        it 'should show connect button link' do
          get "/accounts/#{account.id}/apps/evolution_apis"
          expect(response).to have_http_status(200)
          expect(response.body).to include(pair_qr_code_account_apps_evolution_api_path(account, evolution_api))
          expect(response.body).to include(pair_qr_code_account_apps_evolution_api_path(account,
                                                                                        evolution_api_connecting))
        end
      end
      context 'when there is evolution_api connected' do
        let!(:evolution_api_connected) { create(:apps_evolution_api, :connected) }
        it 'should not show connect button link' do
          get "/accounts/#{account.id}/apps/evolution_apis"
          expect(response).to have_http_status(200)
          expect(response.body).not_to include(pair_qr_code_account_apps_evolution_api_path(account,
                                                                                            evolution_api_connected))
        end
      end
    end
  end

  describe 'GET /accounts/{account.id}/apps/evolution_apis/new' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/apps/evolution_apis/new"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      it 'renders new page' do
        get "/accounts/#{account.id}/apps/evolution_apis/new"
        expect(response).to have_http_status(:success)
        expect(response.body).to include('Connection data')
        expect(flash[:error]).to be_nil
      end
    end
  end

  describe 'GET /accounts/{account.id}/apps/evolution_apis/{evolution_api.id}/edit' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/apps/evolution_apis/#{evolution_api.id}/edit"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      it 'renders edit page' do
        get "/accounts/#{account.id}/apps/evolution_apis/#{evolution_api.id}/edit"
        expect(response).to have_http_status(:success)
        expect(response.body).to include('Connection data')
        expect(flash[:error]).to be_nil
      end
    end
  end

  describe 'POST /accounts/{account.id}/apps/evolution_apis' do
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

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/accounts/#{account.id}/apps/evolution_apis", params: valid_params
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      it 'creates evolution API successfully' do
        expect do
          post "/accounts/#{account.id}/apps/evolution_apis", params: valid_params
        end.to change(Apps::EvolutionApi, :count).by(1)
        expect(response).to redirect_to(pair_qr_code_account_apps_evolution_api_path(account,
                                                                                      Apps::EvolutionApi.last))
        expect(flash[:error]).to be_nil
      end
      context 'when params is invalid' do
        it 'should return unprocessable_entity' do
          expect do
            post "/accounts/#{account.id}/apps/evolution_apis", params: invalid_params
          end.to change(Apps::EvolutionApi, :count).by(0)
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to match(/Name can&#39;t be blank/)
        end
      end
    end
  end

  describe 'PATCH /accounts/{account.id}/apps/evolution_apis/{evolution_api.id}' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch "/accounts/#{account.id}/apps/evolution_apis/#{evolution_api.id}"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      it 'updates evolution API successfully' do
        patch "/accounts/#{account.id}/apps/evolution_apis/#{evolution_api.id}", params: valid_params
        expect(response).to redirect_to(edit_account_apps_evolution_api_path(account, evolution_api))
        expect(flash[:error]).to be_nil
      end
      context 'when params is invalid' do
        it 'should return unprocessable_entity' do
          patch "/accounts/#{account.id}/apps/evolution_apis/#{evolution_api.id}", params: invalid_params
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to match(/Name can&#39;t be blank/)
        end
      end
    end
  end

  describe 'DELETE /accounts/{account.id}/apps/evolution_apis/{evolution_api.id}' do
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

      it 'deletes evolution API successfully' do
        expect do
          delete "/accounts/#{account.id}/apps/evolution_apis/#{evolution_api.id}"
        end.to change(Apps::EvolutionApi, :count).by(-1)
        expect(response).to redirect_to(account_apps_evolution_apis_path(account))
        expect(flash[:error]).to be_nil
      end
    end
  end

  describe 'GET /accounts/{account.id}/apps/evolution_apis/{evolution_api.id}/pair_qr_code' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/apps/evolution_apis/#{evolution_api.id}/pair_qr_code"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      let!(:evolution_api_connecting) { create(:apps_evolution_api, :connecting) }

      before do
        sign_in(user)
      end

      it 'renders pair QR code page' do
        get "/accounts/#{account.id}/apps/evolution_apis/#{evolution_api.id}/pair_qr_code"
        expect(response).to have_http_status(:success)
        expect(flash[:error]).to be_nil
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
        let!(:evolution_api_connected) { create(:apps_evolution_api, :connected) }
        it 'should not show qrcode' do
          get "/accounts/#{account.id}/apps/evolution_apis/#{evolution_api_connected.id}/pair_qr_code"
          expect(response).to have_http_status(200)
          expect(response.body).to include('<img src="" alt="" class="mx-auto lg:m-0">')
        end
      end
    end
  end

  describe 'POST /accounts/{account.id}/apps/evolution_apis/{evolution_api.id}/refresh_qr_code' do
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

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/accounts/#{account.id}/apps/evolution_apis/#{evolution_api.id}/refresh_qr_code"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      it 'refreshes QR code successfully' do
        post "/accounts/#{account.id}/apps/evolution_apis/#{evolution_api.id}/refresh_qr_code"
        expect(response).to have_http_status(:no_content)
        expect(flash[:error]).to be_nil
      end
    end
  end
end
