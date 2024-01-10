require 'rails_helper'
require 'webmock/rspec'

RSpec.describe Accounts::Apps::Chatwoots::RemoveChatwootIdFromContacts, type: :request do
  describe '.call' do
    let!(:account) { create(:account) }
    let!(:contact) { create(:contact, account: account, additional_attributes: {'chatwoot_id': 1}) }
    describe 'success' do
      it do
        Sidekiq::Testing.inline! do
          Accounts::Apps::Chatwoots::RemoveChatwootIdFromContactsWorker.perform_async(account.id)
        end
        expect(account.contacts.count).to eq(1)
        expect(contact.reload.additional_attributes.key?('chatwoot_id')).to eq(false)
      end
    end
  end
end
