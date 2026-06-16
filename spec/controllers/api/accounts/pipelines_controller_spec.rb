require 'rails_helper'

RSpec.describe 'Pipelines API', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user) }
  let(:auth_headers) { { 'Authorization': "Bearer #{user.get_jwt_token}", 'Content-Type': 'application/json' } }

  describe 'GET /api/v1/accounts/:account_id/pipelines' do
    let!(:pipeline) { create(:pipeline, name: 'Sales') }
    let!(:stage_new) { create(:stage, pipeline:, name: 'New', position: 1) }
    let!(:stage_won) { create(:stage, pipeline:, name: 'Won', position: 2) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/pipelines"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    it 'returns pipelines with their stages' do
      get "/api/v1/accounts/#{account.id}/pipelines", headers: auth_headers

      expect(response).to have_http_status(:ok)
      result = JSON.parse(response.body)
      sales = result.find { |pipeline| pipeline['name'] == 'Sales' }
      expect(sales).to be_present
      expect(sales['stages'].map { |stage| stage['name'] }).to include('New', 'Won')
    end
  end
end
