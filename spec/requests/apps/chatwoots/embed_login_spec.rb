require 'rails_helper'

RSpec.describe 'Chatwoot embed_login', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account:) }
  let!(:chatwoot) { create(:apps_chatwoots, :skip_validate, account:, embedding_token: 'tok123') }
  let(:target) { "/accounts/#{account.id}/pipelines" }

  it 'signs the user in, marks the session as embedded, and redirects to the target path' do
    jwt = Users::JsonWebToken.encode_embed(user)
    get '/apps/chatwoots/embed_login', params: { token: 'tok123', jwt:, path: target }

    expect(response).to redirect_to(target)
    expect(session[:embedded]).to be_truthy
  end

  it 'rejects an invalid jwt as unauthorized' do
    get '/apps/chatwoots/embed_login', params: { token: 'tok123', jwt: 'invalid', path: target }

    expect(response).to have_http_status(:unauthorized)
  end

  it 'falls back to root for a non-relative (external) path' do
    jwt = Users::JsonWebToken.encode_embed(user)
    get '/apps/chatwoots/embed_login', params: { token: 'tok123', jwt:, path: 'https://evil.example.com' }

    expect(response).to redirect_to('/')
  end
end
