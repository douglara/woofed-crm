require 'rails_helper'

RSpec.describe Accounts::Contacts::GetByParams, type: :request do
  describe 'success' do
    let!(:account) { create(:account) }
    let!(:contact) { create(:contact, account: account, email: 'tim@maia.com', phone: '+5541988443322' ) }
    let!(:contact_with_chatwoot_identifier) do
      create(:contact, account: account, additional_attributes: { 'chatwoot_identifier' => '123456' }, email: 'user@email.com', phone: '+55123456789',
                       full_name: 'contact with chatwoot_identifier')
    end

    it 'should find by email' do
      result = Accounts::Contacts::GetByParams.call(account, { 'email': 'tim@maia.com' })
      expect(result[:ok]).to eq(contact)
    end

    it 'should find by phone' do
      result = Accounts::Contacts::GetByParams.call(account, { 'phone': '+5541988443322' })
      expect(result[:ok]).to eq(contact)
    end

    it 'should find by phone and email' do
      result = Accounts::Contacts::GetByParams.call(account, { 'email': 'tim@maia.com', 'phone': '+5541988443322' })
      expect(result[:ok]).to eq(contact)
    end

    it 'should find by phone and invalid email' do
      result = Accounts::Contacts::GetByParams.call(account,
                                                    { 'email': 'tim332131@maia.com', 'phone': '+5541988443322' })
      expect(result[:ok]).to eq(contact)
    end

    it 'should find by email and invalid phone' do
      result = Accounts::Contacts::GetByParams.call(account, { 'email': 'tim@maia.com', 'phone': '88443322' })
      expect(result[:ok]).to eq(contact)
    end

    it 'should find by phone without 9 digit' do
      result = Accounts::Contacts::GetByParams.call(account, { 'phone': '+554188443322' })
      expect(result[:ok]).to eq(contact)
    end

    it 'should find by phone without 9 digit and email' do
      result = Accounts::Contacts::GetByParams.call(account, { 'email': 'tim@maia.com', 'phone': '+554188443322' })
      expect(result[:ok]).to eq(contact)
    end

    it 'should return blank if blank params ' do
      result = Accounts::Contacts::GetByParams.call(account, {})
      expect(result[:ok]).to eq(nil)
    end

    it 'with others fields' do
      params = { 'full_name' => 'User Name', 'phone' => '+5561111111111', 'email' => 'email@email.com',
                 'custom_attributes' => { 'lead_origin' => 'Testing' }, 'account_id' => '13', 'contact' => { 'full_name' => 'User name' } }
      result = Accounts::Contacts::GetByParams.call(account, params)
      expect(result[:ok]).to eq(nil)
    end
    it 'should not find contact by invalid identifier' do
      params = { identifier: 'invalid_identifier' }
      result = Accounts::Contacts::GetByParams.call(account, params)
      expect(result[:ok]).to eq(nil)
    end
    it 'should find contact by valid identifier' do
      params = { identifier: '123456' }
      result = Accounts::Contacts::GetByParams.call(account, params)
      expect(result[:ok]).to eq(contact_with_chatwoot_identifier)
    end
    it 'should find contact by valid identifier and valid email' do
      params = { identifier: '123456', email: 'user@email.com' }
      result = Accounts::Contacts::GetByParams.call(account, params)
      expect(result[:ok]).to eq(contact_with_chatwoot_identifier)
    end
  end
  describe 'failed' do
    let!(:account) { create(:account) }
    let!(:contact) { create(:contact, account: account, email: '', phone: '', full_name: 'teste') }

    context 'when there are empty values in params hash keys' do
      it 'when phone and email values are empty' do
        params = { 'phone' => '', 'email' => '' }
        result = Accounts::Contacts::GetByParams.call(account, params)
        expect(result[:ok]).to eq(nil)
      end
    end
  end
end
