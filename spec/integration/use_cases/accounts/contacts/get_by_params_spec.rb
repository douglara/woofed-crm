require 'rails_helper'

RSpec.describe Accounts::Contacts::GetByParams, type: :request do
  describe 'success' do
    let!(:account) { create(:account) }
    let!(:contact) { create(:contact, account: account) }

    it 'should find by email' do
      result = Accounts::Contacts::GetByParams.call(account, {'email': 'tim@maia.com'})
      expect(result[:ok]).to eq(contact)
    end

    it 'should find by phone' do
      result = Accounts::Contacts::GetByParams.call(account, {'phone': '+5541988443322'})
      expect(result[:ok]).to eq(contact)
    end

    it 'should find by phone and email' do
      result = Accounts::Contacts::GetByParams.call(account, {'email': 'tim@maia.com', 'phone': '+5541988443322'})
      expect(result[:ok]).to eq(contact)
    end

    it 'should find by phone and invalid email' do
      result = Accounts::Contacts::GetByParams.call(account, {'email': 'tim332131@maia.com', 'phone': '+5541988443322'})
      expect(result[:ok]).to eq(contact)
    end

    it 'should find by email and invalid phone' do
      result = Accounts::Contacts::GetByParams.call(account, {'email': 'tim@maia.com', 'phone': '88443322'})
      expect(result[:ok]).to eq(contact)
    end

    it 'should find by phone without 9 digit' do
      result = Accounts::Contacts::GetByParams.call(account, {'phone': '+554188443322'})
      expect(result[:ok]).to eq(contact)
    end

    it 'should find by phone without 9 digit and email' do
      result = Accounts::Contacts::GetByParams.call(account, {'email': 'tim@maia.com', 'phone': '+554188443322'})
      expect(result[:ok]).to eq(contact)
    end

    it 'should return blank if blank params ' do
      result = Accounts::Contacts::GetByParams.call(account, {})
      expect(result[:ok]).to eq(nil)
    end

    it 'with others fields' do
      params = {"full_name"=>"User Name", "phone"=>"+5561111111111", "email"=>"email@email.com", "custom_attributes"=>{"lead_origin"=>"Testing"}, "account_id"=>"13", "contact"=>{"full_name"=>"User name"}}
      result = Accounts::Contacts::GetByParams.call(account, params)
      expect(result[:ok]).to eq(nil)
    end
  end
end
