require 'rails_helper'

RSpec.describe 'MCP resource: woofed:///users/{id}', type: :request do
  let!(:account) { create(:account) }
  let!(:requesting_user) { create(:user) }
  let!(:target_user) do
    create(:user, full_name: 'Jane Operator', email: 'jane@operator.com',
                  phone: '+5511999990001', job_description: 'sales_representative', language: 'pt-BR')
  end
  let!(:deal) { create(:deal, name: 'Test Deal') }
  let!(:deal_assignee) { create(:deal_assignee, deal: deal, user: target_user) }
  let(:auth_headers) { mcp_auth_headers(requesting_user) }

  context 'when it is an unauthenticated user' do
    it 'returns unauthorized' do
      post '/mcp', params: mcp_resource_read_body("woofed:///users/#{target_user.id}"),
                   headers: { 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'when it is an authenticated user' do
    it 'returns the user with safe fields and the deals they are assigned to' do
      post '/mcp', params: mcp_resource_read_body("woofed:///users/#{target_user.id}"),
                   headers: auth_headers
      payload = mcp_result

      expect(payload).to include(
        'id' => target_user.id,
        'full_name' => 'Jane Operator',
        'email' => 'jane@operator.com',
        'phone' => '+5511999990001',
        'job_description' => 'sales_representative',
        'language' => 'pt-BR'
      )
      expect(payload).not_to have_key('encrypted_password')
      expect(payload['deals'].pluck('id')).to include(deal.id)
      expect(payload['deals'].pluck('name')).to include('Test Deal')
    end

    it 'returns an error when the user does not exist' do
      post '/mcp', params: mcp_resource_read_body('woofed:///users/99999'),
                   headers: auth_headers
      expect(mcp_text).to match(/Couldn't find|No resource matches/i)
    end
  end
end
