require 'rails_helper'

RSpec.describe 'Chatwoot dashboard_script', type: :request do
  let(:account) { create(:account) }
  let!(:user) { create(:user, account:) }
  let!(:chatwoot) { create(:apps_chatwoots, :skip_validate, account:, embedding_token: 'tok123') }

  it 'serves the widget JS with this integration config interpolated' do
    get '/apps/chatwoots/dashboard_script?token=tok123'

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to include('javascript')
    expect(response.body).to include("EMBED_TOKEN = 'tok123'")
    expect(response.body).to include("WOOFED_ACCOUNT = #{account.id}")
    expect(response.body).to include('woofedShowScreen')
    expect(response.body).to include('addNavMenu')
  end

  it 'returns unauthorized for an unknown token' do
    get '/apps/chatwoots/dashboard_script?token=unknown'
    expect(response).to have_http_status(:bad_request)
  end
end
