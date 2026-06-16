require 'rails_helper'

RSpec.describe 'Contacts by_chatwoot_id API', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account:) }
  let(:auth_headers) { { 'Authorization': "Bearer #{user.get_jwt_token}", 'Content-Type': 'application/json' } }

  describe 'GET /api/v1/accounts/:account_id/contacts/by_chatwoot_id' do
    let!(:contact) do
      create(:contact, account:, full_name: 'John Doe', additional_attributes: { 'chatwoot_id' => 3197 })
    end
    let!(:deal) { create(:deal, account:, contact:, name: 'Test Deal') }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/contacts/by_chatwoot_id?chatwoot_id=3197"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    it 'returns the contact matched by chatwoot_id with deals and events' do
      get "/api/v1/accounts/#{account.id}/contacts/by_chatwoot_id?chatwoot_id=3197", headers: auth_headers

      expect(response).to have_http_status(:ok)
      result = JSON.parse(response.body)
      expect(result['full_name']).to eq('John Doe')
      expect(result['deals'].map { |d| d['name'] }).to include('Test Deal')
      expect(result).to have_key('events')
    end

    it 'returns not found when no contact matches' do
      get "/api/v1/accounts/#{account.id}/contacts/by_chatwoot_id?chatwoot_id=999999", headers: auth_headers

      expect(response).to have_http_status(:not_found)
    end
  end
end
