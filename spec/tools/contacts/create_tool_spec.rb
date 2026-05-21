require 'rails_helper'

RSpec.describe 'MCP tool: contacts_create', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let(:auth_headers) { mcp_auth_headers(user) }
  let(:arguments) do
    { full_name: 'Tim Maia', phone: '+5541996910256', email: 'tim@maia.com',
      label_list: %w[customer vip], custom_attributes: { 'city' => 'RJ' } }
  end
  let(:last_contact) { Contact.last }

  context 'when it is an unauthenticated user' do
    it 'returns unauthorized' do
      expect do
        post '/mcp', params: mcp_tool_call_body('contacts_create', arguments),
                              headers: { 'Content-Type' => 'application/json' }
      end.not_to change(Contact, :count)
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'when it is an authenticated user' do
    it 'creates a contact with all submitted attributes' do
      expect do
        post '/mcp', params: mcp_tool_call_body('contacts_create', arguments), headers: auth_headers
      end.to change(Contact, :count).by(1)
      expect(last_contact).to have_attributes(
        full_name: 'Tim Maia',
        email: 'tim@maia.com',
        phone: '+5541996910256',
        custom_attributes: { 'city' => 'RJ' }
      )
      expect(last_contact.label_list).to match_array(%w[customer vip])
    end

    it 'returns validation errors when the contact is invalid' do
      create(:contact, email: 'tim@maia.com')
      post '/mcp', params: mcp_tool_call_body('contacts_create', arguments), headers: auth_headers
      expect(mcp_text).to include('Validation failed')
      expect(mcp_text).to match(/email/i)
    end
  end
end
