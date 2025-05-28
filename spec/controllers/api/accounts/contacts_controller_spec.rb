require 'rails_helper'

RSpec.describe 'Contacts API', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:contact) { create(:contact, account: account) }
  let(:last_contact) { Contact.last }

  describe 'POST /api/v1/accounts/{account.id}/contacts' do
    let(:valid_params) do
      { full_name: 'Tim maia', phone: '+552299856258', email: 'timaia@email.com', custom_attributes: { "cpf": '123' } }
    end

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
                 headers: { 'Authorization': "Bearer #{user.get_jwt_token}" },
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
        expect do
          post "/api/v1/accounts/#{account.id}/contacts/upsert", params: valid_params
        end.not_to change(Contact, :count)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      context 'create contact' do
        it do
          expect do
            post "/api/v1/accounts/#{account.id}/contacts/upsert",
                 headers: { 'Authorization': "Bearer #{user.get_jwt_token}" },
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
                 headers: { 'Authorization': "Bearer #{user.get_jwt_token}" },
                 params: valid_params
          end.to change(Contact, :count).by(0)

          expect(response).to have_http_status(:success)
          expect(contact.reload.full_name).to eq('Nome novo 123456')
        end
      end

      context 'email is blank' do
        let(:params) { { full_name: 'Teste contato email', email: '' } }
        it do
          expect do
            post "/api/v1/accounts/#{account.id}/contacts/upsert",
                 headers: { 'Authorization': "Bearer #{user.get_jwt_token}" },
                 params: params
          end.to change(Contact, :count).by(1)
          expect(response).to have_http_status(:success)
          expect(last_contact.email).to eq('')
        end
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/contacts/search' do
    let(:valid_params) { { full_name: 'Teste contato 1', email: 'contato@dfgsdfgfdgdfgfg.com' } }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        expect do
          post "/api/v1/accounts/#{account.id}/contacts/search", params: valid_params
        end.not_to change(Contact, :count)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    let(:headers) { { 'Authorization': "Bearer #{user.get_jwt_token}", 'Content-Type': 'application/json' } }

    context 'when it is an authenticated user' do
      context 'search contacts' do
        it do
          post "/api/v1/accounts/#{account.id}/contacts/search",
               headers: headers,
               params: valid_params.to_json

          result = JSON.parse(response.body)
          expect(response).to have_http_status(:success)
          expect(result['pagination']['count']).to eq(1)
        end
      end

      context 'not found contacts' do
        let(:params) { { query: { full_name_eq: 'Contact not found' } }.to_json }
        it do
          post "/api/v1/accounts/#{account.id}/contacts/search",
               headers: headers,
               params: params

          result = JSON.parse(response.body)
          expect(response).to have_http_status(:success)
          expect(result['pagination']['count']).to eq(0)
        end
      end

      context 'with 9 digit' do
        let!(:contact_1) { create(:contact, account: account, phone: '+5511999999999') }
        let!(:contact_2) { create(:contact, account: account, phone: '+551199999999') }

        let(:params) { { query: { phone_cont: '99999999' } }.to_json }
        it do
          post "/api/v1/accounts/#{account.id}/contacts/search",
               headers: headers,
               params: params

          result = JSON.parse(response.body)
          expect(response).to have_http_status(:success)
          expect(result['pagination']['count']).to eq(2)
        end
      end
    end
  end
end
