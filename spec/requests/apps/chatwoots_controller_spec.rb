require 'rails_helper'

RSpec.describe 'Apps::ChatwootsController' do
  describe 'GET /apps/chatwoots/embedding' do
    let!(:chatwoot) { create(:apps_chatwoots, :skip_validate) }

    it 'returns 200 with the Stimulus data-attributes' do
      get embedding_apps_chatwoots_path, params: { token: chatwoot.embedding_token }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('apps--chatwoot-embed-auth')
      expect(response.body).to include(chatwoot.embedding_token)
    end

    it 'returns 400 for an invalid embedding token' do
      get embedding_apps_chatwoots_path, params: { token: 'invalid_token' }
      expect(response).to have_http_status(:bad_request)
    end
  end
end
