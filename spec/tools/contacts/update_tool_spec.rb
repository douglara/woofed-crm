require 'rails_helper'

RSpec.describe 'MCP tool: contacts_update', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:contact) do
    create(:contact, full_name: 'Old Name', email: 'old@example.com', phone: '+5511999990001',
                     label_list: ['old'], custom_attributes: { 'city' => 'SP' })
  end
  let(:auth_headers) { mcp_auth_headers(user) }
  let(:arguments) do
    { id: contact.id, full_name: 'New Name', email: 'new@example.com', phone: '+5511999998888',
      label_list: ['vip'], custom_attributes: { 'city' => 'RJ' } }
  end

  context 'when it is an unauthenticated user' do
    it 'returns unauthorized' do
      post '/mcp', params: mcp_tool_call_body('contacts_update', arguments),
                            headers: { 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:unauthorized)
      expect(contact.reload.full_name).to eq('Old Name')
    end
  end

  context 'when it is an authenticated user' do
    it 'updates all submitted attributes' do
      post '/mcp', params: mcp_tool_call_body('contacts_update', arguments), headers: auth_headers
      expect(contact.reload).to have_attributes(
        full_name: 'New Name',
        email: 'new@example.com',
        phone: '+5511999998888',
        custom_attributes: { 'city' => 'RJ' }
      )
      expect(contact.label_list).to match_array(['vip'])
    end

    it 'returns not found when the contact does not exist' do
      post '/mcp', params: mcp_tool_call_body('contacts_update', { id: 99_999, full_name: 'x' }),
                            headers: auth_headers
      expect(mcp_text).to match(/not.*found|Couldn't find/i)
    end

    it 'returns a uniqueness violation when the email is already taken by another contact' do
      create(:contact, email: 'taken@example.com')
      post '/mcp', params: mcp_tool_call_body('contacts_update',
                                                        { id: contact.id, email: 'taken@example.com' }),
                            headers: auth_headers
      expect(mcp_text).to include('Validation failed')
      expect(mcp_text).to match(/email/i)
    end

    context 'when required arguments are missing' do
      it 'returns a schema validation error when id is missing' do
        post '/mcp', params: mcp_tool_call_body('contacts_update', { full_name: 'x' }),
                              headers: auth_headers
        expect(mcp_response.dig('result', 'isError')).to eq(true)
        expect(mcp_response.dig('result', 'content', 0, 'text')).to match(/id/i)
      end
    end
  end
end
