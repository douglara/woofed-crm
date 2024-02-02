require 'rails_helper'

RSpec.describe 'Contacts API', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:contact) { create(:contact, account: account) }
  let(:last_contact) { Contact.last }

  describe 'POST /api/v1/accounts/{account.id}/contacts' do
    let(:valid_params) { { full_name: contact.full_name, phone: contact.phone, email: contact.email, custom_attributes: {"cpf": "123"} } }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        expect { post "/api/v1/accounts/#{account.id}/contacts", params: valid_params }.not_to change(Contact, :count)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      context 'create contact' do
        it do
          expect do
            post "/api/v1/accounts/#{account.id}/contacts",
            headers: {'Authorization': "Bearer #{user.get_jwt_token}"},
            params: valid_params
          end.to change(Contact, :count).by(1)

          expect(response).to have_http_status(:success)
          expect(last_contact.custom_attributes['cpf']).to eq('123')
        end
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/contacts/upsert' do
    let(:valid_params) { { full_name: 'Teste contato 1', email: 'contato@dfgsdfgfdgdfgfg.com' } }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        expect { post "/api/v1/accounts/#{account.id}/contacts/upsert", params: valid_params }.not_to change(Contact, :count)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      context 'create contact' do
          it do
          expect do
          post "/api/v1/accounts/#{account.id}/contacts/upsert",
          headers: {'Authorization': "Bearer #{user.get_jwt_token}"},
          params: valid_params
          end.to change(Contact, :count).by(1)

          expect(response).to have_http_status(:success)
          end
      end

      context 'update contact' do
        let(:valid_params) { { full_name: 'Nome novo 123456', phone: contact.phone, email: contact.email } }

        it 'update name' do
          expect do
            post "/api/v1/accounts/#{account.id}/contacts/upsert",
            headers: {'Authorization': "Bearer #{user.get_jwt_token}"},
            params: valid_params
          end.to change(Contact, :count).by(0)

          expect(response).to have_http_status(:success)
          expect(contact.reload.full_name).to eq('Nome novo 123456')
        end
      end

      context 'invalid params' do
        let(:valid_params) { { name: 'Nome novo 123456', phone_number: contact.phone } }

        it 'update name' do
          expect do
            post "/api/v1/accounts/#{account.id}/contacts/upsert",
            headers: {'Authorization': "Bearer #{user.get_jwt_token}"},
            params: valid_params
          end.to change(Contact, :count).by(0)

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body.include?('full_name')).to eq(true)
        end
      end
      context 'email is blank' do
        let(:params) { { full_name: 'Teste contato email', email: "" } }
        it do
          expect do
            post "/api/v1/accounts/#{account.id}/contacts/upsert",
            headers: {'Authorization': "Bearer #{user.get_jwt_token}"},
            params: params
          end.to change(Contact, :count).by(0)
          expect(response).to have_http_status(:success)
          expect(contact.reload.email).to eq("")
        end
      end
    end
  end
end
