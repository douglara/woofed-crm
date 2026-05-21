require 'rails_helper'

RSpec.describe 'MCP resource: woofed:///contacts/{id}', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:contact) do
    create(:contact, full_name: 'John Doe', email: 'john@example.com', phone: '+5511999990001',
                     custom_attributes: { 'city' => 'RJ' }, label_list: %w[vip customer])
  end
  let!(:deal) { create(:deal, contact: contact, name: 'Test Deal') }
  let!(:event) { create(:event, contact: contact, deal: deal, kind: 'activity', title: 'Test Event') }
  let(:auth_headers) { mcp_auth_headers(user) }

  context 'when it is an unauthenticated user' do
    it 'returns unauthorized' do
      post '/mcp', params: mcp_resource_read_body("woofed:///contacts/#{contact.id}"),
                            headers: { 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'when it is an authenticated user' do
    it 'returns the contact with all fields and its deals and events' do
      post '/mcp', params: mcp_resource_read_body("woofed:///contacts/#{contact.id}"),
                            headers: auth_headers
      payload = mcp_result

      expect(payload).to include(
        'id' => contact.id,
        'full_name' => 'John Doe',
        'email' => 'john@example.com',
        'phone' => '+5511999990001',
        'custom_attributes' => { 'city' => 'RJ' }
      )
      expect(payload['deals'].pluck('id')).to include(deal.id)
      expect(payload['deals'].pluck('name')).to include('Test Deal')
      expect(payload['events'].pluck('id')).to include(event.id)
      expect(payload['events'].pluck('title')).to include('Test Event')
      expect(payload['events'].pluck('kind')).to include('activity')
    end

    it 'returns an error when the contact does not exist' do
      post '/mcp', params: mcp_resource_read_body('woofed:///contacts/99999'),
                            headers: auth_headers
      expect(mcp_text).to match(/Couldn't find|No resource matches/i)
    end
  end
end
