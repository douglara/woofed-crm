require 'rails_helper'

RSpec.describe 'Contacts API', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account:) }
  let(:auth_headers) { { 'Authorization': "Bearer #{user.get_jwt_token}", 'Content-Type': 'application/json' } }

  describe 'GET /api/v1/accounts/{account.id}/contacts/{contact.id}' do
    let!(:contact) do
      create(:contact, account:, full_name: 'John Doe', email: 'john.doe@example.com', phone: '+5522998813788')
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/contacts/#{contact.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let!(:deal) { create(:deal, account:, contact:, name: 'Test Deal') }
      let!(:event) { create(:event, account:, contact:, deal:, kind: 'activity', title: 'Test Event') }

      it 'returns contact details with included deals and events' do
        get("/api/v1/accounts/#{account.id}/contacts/#{contact.id}", headers: auth_headers)
        expect(response).to have_http_status(:ok)
        result = JSON.parse(response.body)

        expect(result['full_name']).to eq('John Doe')
        expect(result['email']).to eq('john.doe@example.com')
        expect(result['phone']).to eq('+5522998813788')
        expect(result['deals'].map { |d| d['name'] }).to include('Test Deal')
        expect(result['events'].map { |e| e['title'] }).to include('Test Event')
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/contacts' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        expect do
          post "/api/v1/accounts/#{account.id}/contacts", params: {},
                                                          headers: { 'Content-Type': 'application/json' }
        end.not_to change(Contact, :count)
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:params) do
        { full_name: 'Tim Maia', phone: '+552299856258', email: 'timaia@email.com',
          custom_attributes: { 'cpf' => '123' } }.to_json
      end

      it 'creates a contact' do
        expect do
          post "/api/v1/accounts/#{account.id}/contacts", params:, headers: auth_headers
        end.to change(Contact, :count).by(1)
        expect(response).to have_http_status(:created)
        result = JSON.parse(response.body)
        expect(result['full_name']).to eq('Tim Maia')
        expect(result['email']).to eq('timaia@email.com')
        expect(result['phone']).to eq('+552299856258')
        expect(result['custom_attributes']['cpf']).to eq('123')
      end

      context 'when contact creation fails' do
        let!(:contact) do
          create(:contact, account:, full_name: 'John Doe', email: 'john.doe@example.com', phone: '+5522998813788')
        end

        it 'returns unprocessable_entity with errors' do
          params = { full_name: 'Tim Maia', phone: contact.phone, email: 'timaia@email.com' }.to_json
          expect do
            post "/api/v1/accounts/#{account.id}/contacts", params:, headers: auth_headers
          end.not_to change(Contact, :count)
          expect(response).to have_http_status(:unprocessable_entity)
          result = JSON.parse(response.body)
          expect(result['errors']).to include('Phone (cell) has already been taken')
        end
      end
    end
  end

  describe 'POST /api/v1/accounts/:account_id/contacts/upsert' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        expect do
          post "/api/v1/accounts/#{account.id}/contacts/upsert", params: {}
        end.to change(Contact, :count).by(0)
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:params) { { full_name: 'Test Contact 1', email: 'contato@dfgsdfgfdgdfgfg.com' }.to_json }

      it 'creates new contact' do
        expect do
          post "/api/v1/accounts/#{account.id}/contacts/upsert", params:, headers: auth_headers
        end.to change(Contact, :count).by(1)
        expect(response).to have_http_status(:created)
        result = JSON.parse(response.body)
        expect(result['full_name']).to eq('Test Contact 1')
        expect(result['email']).to eq('contato@dfgsdfgfdgdfgfg.com')
        expect(Contact.last.account).to eq(account)
      end

      context 'when updating existing contact' do
        let!(:existing_contact) do
          create(:contact, account:, full_name: 'Original Name', email: 'contato@dfgsdfgfdgdfgfg.com')
        end

        it 'updates contact name' do
          params = { full_name: 'Updated Name', email: existing_contact.email }.to_json
          expect do
            post "/api/v1/accounts/#{account.id}/contacts/upsert", params:, headers: auth_headers
          end.to change(Contact, :count).by(0)
          expect(response).to have_http_status(:ok)
          expect(existing_contact.reload.full_name).to eq('Updated Name')
          result = JSON.parse(response.body)
          expect(result['full_name']).to eq('Updated Name')
        end
      end

      context 'when params are invalid' do
        it 'returns unprocessable_entity with errors' do
          params = { full_name: 'Test Contact', phone: '+552299856258888545454' }.to_json
          expect do
            post "/api/v1/accounts/#{account.id}/contacts/upsert", params:, headers: auth_headers
          end.to change(Contact, :count).by(0)
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)['phone']).to include('must be in e164 format')
        end
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/contacts/search' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/contacts/search", params: {},
                                                               headers: { 'Content-Type': 'application/json' }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let!(:contact) do
        create(:contact, account:, full_name: 'John Doe', email: 'john.doe@example.com', phone: '+5522998813788')
      end
      let(:params) { { query: { full_name_cont: 'John Doe' } }.to_json }

      it 'returns matching contacts' do
        post("/api/v1/accounts/#{account.id}/contacts/search", params:, headers: auth_headers)
        expect(response).to have_http_status(:ok)
        result = JSON.parse(response.body)
        expect(result['pagination']['count']).to eq(1)
        expect(result['data'].first['full_name']).to eq('John Doe')
        expect(result['data'].first['email']).to eq('john.doe@example.com')
        expect(result['data'].first['phone']).to eq('+5522998813788')
      end

      it 'returns no contacts when query does not match' do
        params = { query: { full_name_cont: 'Contact not found' } }.to_json
        post("/api/v1/accounts/#{account.id}/contacts/search", params:, headers: auth_headers)
        expect(response).to have_http_status(:ok)
        result = JSON.parse(response.body)
        expect(result['pagination']['count']).to eq(0)
        expect(result['data']).to be_empty
      end

      context 'when searching by phone with 9 digits' do
        let!(:contact_1) { create(:contact, account:, phone: '+5511999999999') }
        let!(:contact_2) { create(:contact, account:, phone: '+551199999999') }

        it 'returns matching contacts' do
          params = { query: { phone_cont: '99999999' } }.to_json
          post("/api/v1/accounts/#{account.id}/contacts/search", params:, headers: auth_headers)
          expect(response).to have_http_status(:ok)
          result = JSON.parse(response.body)
          expect(result['pagination']['count']).to eq(2)
          expect(result['data'].map { |c| c['phone'] }).to include('+5511999999999', '+551199999999')
        end
      end

      context 'when params is invalid' do
        context 'when there is no ransack prefix to contact params' do
          it 'should raise an error' do
            params = { query: { full_name: contact.full_name, email: contact.email } }.to_json

            post("/api/v1/accounts/#{account.id}/contacts/search",
                  headers: auth_headers,
                  params:)
            expect(response).to have_http_status(:unprocessable_entity)
            json = JSON.parse(response.body)
            expect(json['errors']).to eq('Invalid search parameters')
            expect(json['details']).to eq('No valid predicate for full_name')
          end
        end
      end
    end
  end
end
