require 'rails_helper'
require 'webmock/rspec'

RSpec.describe Accounts::Apps::Chatwoots::RemoveChatwootIdFromContacts, type: :request do
  describe '.call' do
    let!(:account) { create(:account) }
    let!(:chatwoot) { create(:apps_chatwoots, :skip_validate, account: account) }
    let!(:contact) { create(:contact, account: account, additional_attributes: {'chatwoot_id': 1}) }
    describe 'success' do
      it do
        result = Accounts::Apps::Chatwoots::RemoveChatwootIdFromContacts.call(account)
        expect(result.key?(:ok)).to eq(true)
        expect(account.contacts.count).to eq(1)
        expect(contact.reload.additional_attributes.key?('chatwoot_id')).to eq(false)
      end
    end
  end
end
