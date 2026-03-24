require 'rails_helper'

RSpec.describe 'POST /apps/chatwoots/embedding_generate_jwt' do
  let(:chatwoot) { create(:apps_chatwoots, :skip_validate) }
  let(:user) { create(:user, email: 'agent@example.com') }
  let(:event_json) do
    { data: { currentAgent: { email: user.email }, contact: { id: 1 } } }.to_json
  end

  it 'returns a JWT for a known user' do
    post embedding_generate_jwt_apps_chatwoots_path,
         params: { token: chatwoot.embedding_token, event: event_json }

    expect(response).to have_http_status(:ok)
    jwt = JSON.parse(response.body)['jwt']
    expect(Users::JsonWebToken.decode_embed(jwt)[:ok]).to eq(user)
  end

  it 'returns 404 when the email is not found in WoofedCRM' do
    event = { data: { currentAgent: { email: 'ghost@example.com' } } }.to_json
    post embedding_generate_jwt_apps_chatwoots_path,
         params: { token: chatwoot.embedding_token, event: }
    expect(response).to have_http_status(:not_found)
  end

  it 'returns 400 for an invalid Chatwoot token' do
    post embedding_generate_jwt_apps_chatwoots_path,
         params: { token: 'invalid', event: event_json }
    expect(response).to have_http_status(:bad_request)
  end
end
