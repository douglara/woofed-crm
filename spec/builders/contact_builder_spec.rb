require 'rails_helper'
require 'action_controller'

RSpec.describe ContactBuilder do
  let!(:account) { create(:account) }
  let!(:contact) { create(:contact, account: account) }
  let!(:user) { create(:user, account: account) }

  describe 'when search_if_exists is set to true' do
    context 'when there is contact with params set' do
      let(:params) do
        ActionController::Parameters.new(
          {
            phone: contact.phone,
            email: contact.email
          }
        )
      end
      it 'should find and return contact' do
        contact_found = described_class.new(user, params, true).perform
        expect(contact_found.full_name).to eq(contact.full_name)
        expect(contact_found.phone).to eq(contact.phone)
        expect(contact_found.email).to eq(contact.email)
        expect(contact_found.id).to eq(contact.id)
      end
    end
    context 'when there is no contact with params set' do
      let(:params) do
        ActionController::Parameters.new(
          {
            phone: '+546546546546'
          }
        )
      end
      it 'should not find and return a new contact object' do
        contact_found = described_class.new(user, params, true).perform
        expect(contact_found.full_name).to eq('')
        expect(contact_found.phone).to eq('+546546546546')
        expect(contact_found.email).to eq('')
        expect(contact_found.id).to be_nil
      end
    end
  end
  describe 'when search_if_exists is set to false' do
    context 'when there is contact with params set' do
      let(:params) do
        ActionController::Parameters.new(
          {
            phone: contact.phone,
            email: contact.email,
            full_name: 'teste'
          }
        )
      end
      it 'should return new contact object' do
        contact_found = described_class.new(user, params, false).perform
        expect(contact_found.full_name).to eq('teste')
        expect(contact_found.phone).to eq(contact.phone)
        expect(contact_found.email).to eq(contact.email)
        expect(contact_found.id).to be_nil
      end
    end
    context 'when there is no contact with params set' do
      let(:params) do
        ActionController::Parameters.new(
          {
            phone: '+546546546546'
          }
        )
      end
      it 'should return new contact object' do
        contact_found = described_class.new(user, params, false).perform
        expect(contact_found.full_name).to eq('')
        expect(contact_found.phone).to eq('+546546546546')
        expect(contact_found.email).to eq('')
      end
    end
  end
end
