require 'rails_helper'
require 'webmock/rspec'

RSpec.describe Accounts::Apps::Chatwoots::SyncImportContacts, type: :request do
  describe '.call' do
    let(:account) { create(:account) }
    let(:chatwoot) { create(:apps_chatwoots, :skip_validate, account: account) }
    let(:contact_list_page_1) { File.read("spec/integration/use_cases/accounts/apps/chatwoots/get_all_contacts_page_1.json") }
    let(:contact_list_page_2) { File.read("spec/integration/use_cases/accounts/apps/chatwoots/get_all_contacts_page_2.json") }
    
    describe 'success' do
      before do 
        stub_request(:get, "#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/contacts/")
          .with(
            query: { page: 1 },
            headers: chatwoot.request_headers
          )
          .to_return(status: 200, body: contact_list_page_1, headers: { 'Content-Type' => 'application/json' })
          stub_request(:get, "#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/contacts/")
          .with(
            query: { page: 2 },
            headers: chatwoot.request_headers
          )
          .to_return(status: 200, body: contact_list_page_2, headers: { 'Content-Type' => 'application/json' })
      end
      it 'import contact data to Chatwoot API' do
        result = Accounts::Apps::Chatwoots::SyncImportContacts.call(chatwoot)
        expect(result.key?(:ok)).to eq(true)
        expect(account.contacts.count).to eq(30)
      end
      context 'if contact exists in both sides' do
        let!(:contact) { create(:contact, account: account, full_name: "BBBBBBBBBBBBBBBBBBBBB", email: "bbbb@eamil.com", phone: "+5522998813788")}
        it 'should add chatwoot_id in contact'do
        result = Accounts::Apps::Chatwoots::SyncImportContacts.call(chatwoot)
        expect(result.key?(:ok)).to eq(true)
        expect(account.contacts.count).to eq(30)
        expect(contact.reload.additional_attributes.key?('chatwoot_id')).to eq(true)
        end
      end
      context 'if contact exist in woofed but not in chatwoot' do
        let!(:contact) { create(:contact, account: account)}
        it do
        result = Accounts::Apps::Chatwoots::SyncImportContacts.call(chatwoot)
        expect(result.key?(:ok)).to eq(true)
        expect(account.contacts.count).to eq(31)
        end
      end
    end
  end
end
