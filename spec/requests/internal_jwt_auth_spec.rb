require 'rails_helper'

RSpec.describe 'InternalController JWT auth fallback' do
  let!(:account) { create(:account) }
  let(:user) { create(:user) }
  let(:protected_path) { account_contacts_path(account) }

  context 'JWT authentication' do
    context 'Authorization: Bearer header (Turbo/Inertia XHR)' do
      it 'authenticates with a valid JWT' do
        jwt = Users::JsonWebToken.encode_embed(user)
        get protected_path, headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response).not_to redirect_to(new_user_session_path)
        # JWT auth should not create a Devise session
        expect(session[:warden_user_user_key]).to be_nil
      end

      it 'skips CSRF on POST with JWT' do
        jwt = Users::JsonWebToken.encode_embed(user)
        post protected_path, headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response.status).not_to eq(422)
      end
    end

    context 'params[:embed_jwt] (full page reload with JWT in URL)' do
      it 'authenticates via query param' do
        jwt = Users::JsonWebToken.encode_embed(user)
        get protected_path, params: { embed_jwt: jwt }
        expect(response).not_to redirect_to(new_user_session_path)
      end

      it 'header takes precedence over query param when both are present' do
        valid_jwt   = Users::JsonWebToken.encode_embed(user)
        expired_jwt = travel_to(9.hours.ago) { Users::JsonWebToken.encode_embed(user) }
        get protected_path,
            headers: { 'Authorization' => "Bearer #{expired_jwt}" },
            params:  { embed_jwt: valid_jwt }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    context 'token without embed audience (API token)' do
      it 'rejects token without aud and redirects to login' do
        legacy_token = Users::JsonWebToken.encode_user(user)
        get protected_path, headers: { 'Authorization' => "Bearer #{legacy_token}" }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'Authorization header with Token scheme' do
      it 'authenticates with Token scheme (accepted by Rails HTTP Token auth)' do
        jwt = Users::JsonWebToken.encode_embed(user)
        get protected_path, headers: { 'Authorization' => "Token #{jwt}" }
        expect(response).not_to redirect_to(new_user_session_path)
      end
    end

    # Simulates the Authorization: Bearer header injected by router.on('before', ...) in inertia.tsx
    context 'Inertia controller endpoint (combobox)' do
      let(:combobox_path) { inertia_account_components_combobox_path(account, model: 'contact') }

      it 'authenticates with JWT in Authorization header' do
        jwt = Users::JsonWebToken.encode_embed(user)
        get combobox_path, headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response).to be_successful
        expect(response.parsed_body).to be_an(Array)
        # JWT auth should not create a Devise session
        expect(session[:warden_user_user_key]).to be_nil
      end

      it 'redirects to login without JWT and without session' do
        get combobox_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  context 'Cookie-based authentication' do
    it 'uses Devise cookie normally' do
      sign_in user
      get protected_path
      expect(response).to be_successful
    end

    it 'redirects to login without cookie and without JWT' do
      get protected_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
