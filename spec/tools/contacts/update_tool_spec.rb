require 'rails_helper'

RSpec.describe 'MCP tool: contacts_update', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:contact) do
    create(:contact, full_name: 'Old Name', email: 'old@example.com', phone: '+5511999990001',
                     label_list: ['old'], custom_attributes: { 'city' => 'SP' })
  end
  let(:auth_headers) do
    { 'Authorization' => "Bearer #{Users::JsonWebToken.encode_user(user)}",
      'Content-Type' => 'application/json' }
  end
  let(:arguments) do
    { id: contact.id, full_name: 'New Name', email: 'new@example.com', phone: '+5511999998888',
      label_list: ['vip'], custom_attributes: { 'city' => 'RJ' } }
  end

  context 'when it is an unauthenticated user' do
    it 'returns unauthorized' do
      post '/mcp/messages', params: mcp_tool_call_body('contacts_update', arguments),
                            headers: { 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:unauthorized)
      expect(contact.reload.full_name).to eq('Old Name')
    end
  end

  context 'when it is an authenticated user' do
    it 'updates all submitted attributes' do
      post '/mcp/messages', params: mcp_tool_call_body('contacts_update', arguments), headers: auth_headers
      expect(contact.reload).to have_attributes(
        full_name: 'New Name',
        email: 'new@example.com',
        phone: '+5511999998888',
        custom_attributes: { 'city' => 'RJ' }
      )
      expect(contact.label_list).to match_array(['vip'])
    end

    it 'returns not found when the contact does not exist' do
      post '/mcp/messages', params: mcp_tool_call_body('contacts_update', { id: 99_999, full_name: 'x' }),
                            headers: auth_headers
      expect(mcp_result).to include('status' => 'not_found',
                                    'error' => 'Resource could not be found')
    end

    it 'returns a uniqueness violation when the email is already taken by another contact' do
      create(:contact, email: 'taken@example.com')
      post '/mcp/messages', params: mcp_tool_call_body('contacts_update',
                                                        { id: contact.id, email: 'taken@example.com' }),
                            headers: auth_headers
      expect(mcp_result).to include('status' => 'unprocessable_entity')
      expect(mcp_result['error']).to include(match(/email/i))
    end
  end
end
