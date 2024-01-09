require 'rails_helper'
require 'webmock/rspec'

RSpec.describe Accounts::Apps::Chatwoots::SyncImportContacts, type: :request do
  describe '.call' do
    let(:account) { create(:account) }
    let(:chatwoot) { create(:apps_chatwoots, :skip_validate, account: account) }
    let(:contact_list_page_1) do
      File.read('spec/integration/use_cases/accounts/apps/chatwoots/get_all_contacts_page_1.json')
    end
    let(:contact_list_page_2) do
      File.read('spec/integration/use_cases/accounts/apps/chatwoots/get_all_contacts_page_2.json')
    end
    let(:contact_list_page_3) do
      File.read('spec/integration/use_cases/accounts/apps/chatwoots/get_all_contacts_page_3.json')
    end
    let(:response_conversations) do
      File.read('spec/integration/use_cases/accounts/apps/chatwoots/webhooks/events/response_conversations.json')
    end

    describe 'success' do
      before do
        stub_request(:get, /conversations/)
          .to_return(body: response_conversations, status: 200, headers: { 'Content-Type' => 'application/json' })
        stub_request(:get, /labels/)
          .to_return(body: { payload: ['marcador1'] }.to_json, status: 200, headers: { 'Content-Type' => 'application/json' })
        stub_request(:put, "#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/contacts/#{JSON.parse(contact_list_page_1)['payload'].first['id']}")
          .to_return(status: 200, body: contact_list_page_1, headers: { 'Content-Type' => 'application/json' })
        stub_request(:put, "#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/contacts/#{JSON.parse(contact_list_page_2)['payload'].first['id']}")
          .to_return(status: 200, body: contact_list_page_2, headers: { 'Content-Type' => 'application/json' })
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
        stub_request(:get, "#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/contacts/")
          .with(
            query: { page: 3 },
            headers: chatwoot.request_headers
          )
          .to_return(status: 200, body: contact_list_page_3, headers: { 'Content-Type' => 'application/json' })
      end
      it 'import contact data to Chatwoot API' do
        Sidekiq::Testing.inline! do
          Accounts::Apps::Chatwoots::SyncImportContactsWorker.perform_async(chatwoot.id)
        end
        expect(account.contacts.count).to eq(2)
      end
      context 'if contact exists in both sides' do
        let!(:contact) do
          create(:contact, account: account, full_name: 'BBBBBBBBBBBBBBBBBBBBB', email: 'bbbb@eamil.com',
                           phone: '+5522998813788')
        end
        it 'should add chatwoot_id in contact' do
          Sidekiq::Testing.inline! do
            Accounts::Apps::Chatwoots::SyncImportContactsWorker.perform_async(chatwoot.id)
          end
          expect(account.contacts.count).to eq(2)
          expect(contact.reload.additional_attributes.key?('chatwoot_id')).to eq(true)
        end
      end
      context 'if contact exist in woofed but not in chatwoot' do
        let!(:contact) { create(:contact, account: account) }
        it do
          Sidekiq::Testing.inline! do
            Accounts::Apps::Chatwoots::SyncImportContactsWorker.perform_async(chatwoot.id)
          end
          expect(account.contacts.count).to eq(3)
        end
      end
      context 'check labels and conversations tags' do
        let(:contact) do
          create(:contact, account: account, email: 'bbbb@eamil.com', full_name: 'BBBBBBBBBBBBBBBBBBBBB',
                           label_list: %w[marcador1 marcador2 marcador3])
        end
        it do
          Sidekiq::Testing.inline! do
            Accounts::Apps::Chatwoots::SyncImportContactsWorker.perform_async(chatwoot.id)
          end
          expect(account.contacts.count).to eq(2)
          expect(account.contacts.first.label_list).to eq(['marcador1'])
          expect(account.contacts.first.chatwoot_conversations_label_list).to eq(['test1'])
          expect(account.contacts.map(&:additional_attributes)).to eq([{ 'chatwoot_id' => 63 },
                                                                       { 'chatwoot_id' => 338 }])
        end
        it 'if contact already exists on woofed' do
          contact
          expect(account.contacts.first.label_list).to eq(%w[marcador1 marcador2 marcador3])
          Sidekiq::Testing.inline! do
            Accounts::Apps::Chatwoots::SyncImportContactsWorker.perform_async(chatwoot.id)
          end
          expect(account.contacts.count).to eq(2)
          expect(account.contacts.first.label_list).to eq(['marcador1'])
          expect(account.contacts.first.chatwoot_conversations_label_list).to eq(['test1'])
          expect(account.contacts.map(&:additional_attributes)).to eq([{ 'chatwoot_id' => 63 },
                                                                       { 'chatwoot_id' => 338 }])
        end
        it 'if there is no label on chatwoot contact but there is on contact woofed' do
          stub_request(:get, /labels/)
            .to_return(body: { payload: [] }.to_json, status: 200, headers: { 'Content-Type' => 'application/json' })
          contact
          expect(account.contacts.first.label_list).to eq(%w[marcador1 marcador2 marcador3])
          Sidekiq::Testing.inline! do
            Accounts::Apps::Chatwoots::SyncImportContactsWorker.perform_async(chatwoot.id)
          end
          expect(account.contacts.count).to eq(2)
          expect(account.contacts.first.label_list).to eq([])
          expect(account.contacts.first.chatwoot_conversations_label_list).to eq(['test1'])
          expect(account.contacts.map(&:additional_attributes)).to eq([{ 'chatwoot_id' => 63 },
                                                                       { 'chatwoot_id' => 338 }])
        end
      end
    end
  end
end
