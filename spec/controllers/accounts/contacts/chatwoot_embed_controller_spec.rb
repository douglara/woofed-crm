require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe Accounts::Contacts::ChatwootEmbedController, type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user) }
  let!(:contact) { create(:contact) }
  let!(:chatwoot) { create(:apps_chatwoots, :skip_validate) }
  let(:last_contact) { Contact.last }

  describe 'GET /accounts/{account.id}/contacts/chatwoot_embed/{contact.id}' do
    context 'when it is unthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/contacts/chatwoot_embed/#{contact.id}"
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end
      it 'should redirect to show embed chatwoot page' do
        get "/accounts/#{account.id}/contacts/chatwoot_embed/#{contact.id}"
        expect(response).to have_http_status(200)
        expect(response.body).to include(contact.full_name)
      end
    end
  end

  describe 'POST /accounts/{account.id}/contacts/chatwoot_embed/search' do
    context 'when it is unthenticated user' do
      it 'returns unauthorized' do
        post "/accounts/#{account.id}/contacts/chatwoot_embed/search", params: { chatwoot_contact: {} }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end
      context 'when the chatwoot_params contains data for an existing contact' do
        context 'when there are all params on chatwoot_params' do
          let(:params) do
            { chatwoot_contact: { name: contact.full_name, phone_number: contact.phone, email: contact.email }.to_json }
          end
          it 'should redirect to show embed chatwoot page' do
            post("/accounts/#{account.id}/contacts/chatwoot_embed/search", params:)
            expect(response).to have_http_status(302)
            expect(response).to redirect_to(account_chatwoot_embed_path(account, contact))
            follow_redirect!
            expect(response.body).to include(contact.full_name)
            expect(response.body).to include(contact.email)
            expect(response.body).to include(contact.phone)
          end
        end
        context 'when there is email on chatwoot_params' do
          let(:params) do
            { chatwoot_contact: { email: contact.email }.to_json }
          end
          it 'should redirect to show embed chatwoot page' do
            post("/accounts/#{account.id}/contacts/chatwoot_embed/search", params:)
            expect(response).to have_http_status(302)
            expect(response).to redirect_to(account_chatwoot_embed_path(account, contact))
            follow_redirect!
            expect(response.body).to include(contact.full_name)
            expect(response.body).to include(contact.email)
            expect(response.body).to include(contact.phone)
          end
        end
        context 'when there is phone_number on chatwoot_params' do
          let(:params) do
            { chatwoot_contact: { phone_number: contact.phone }.to_json }
          end
          it 'should redirect to show embed chatwoot page' do
            post("/accounts/#{account.id}/contacts/chatwoot_embed/search", params:)
            expect(response).to have_http_status(302)
            expect(response).to redirect_to(account_chatwoot_embed_path(account, contact))
            follow_redirect!
            expect(response.body).to include(contact.full_name)
            expect(response.body).to include(contact.email)
            expect(response.body).to include(contact.phone)
          end
        end
      end
      context 'when the chatwoot_params contains data for a non-existent contact' do
        context 'when there are all params on chatwoot_params' do
          let(:params) do
            { chatwoot_contact: { name: 'yukio', phone_number: '+55229988132',
                                  email: 'non-existent_contact@email.com' }.to_json }
          end
          it 'should render to new embed chatwoot page' do
            post("/accounts/#{account.id}/contacts/chatwoot_embed/search", params:)
            expect(response).to have_http_status(200)
            expect(response.body).to include('This contact does not exist in Woofed CRM. Would you like to create it?')
          end
        end
        context 'when there is email on chatwoot_params' do
          let(:params) do
            { chatwoot_contact: { email: 'non-existent_contact@email.com' }.to_json }
          end
          it 'should render to new embed chatwoot page' do
            post("/accounts/#{account.id}/contacts/chatwoot_embed/search", params:)
            expect(response).to have_http_status(200)
            expect(response.body).to include('This contact does not exist in Woofed CRM. Would you like to create it?')
          end
        end
        context 'when there is phone_number on chatwoot_params' do
          let(:params) do
            { chatwoot_contact: { phone_number: '+55229988132' }.to_json }
          end
          it 'should render to new embed chatwoot page' do
            post("/accounts/#{account.id}/contacts/chatwoot_embed/search", params:)
            expect(response).to have_http_status(200)
            expect(response.body).to include('This contact does not exist in Woofed CRM. Would you like to create it?')
          end
        end
      end
    end
  end

  describe 'GET /accounts/{account.id}/contacts/chatwoot_embed/new' do
    let(:params) do
      { chatwoot_contact: { name: 'yukio', phone_number: '+55229988132',
                            email: 'non-existent_contact@email.com' }.to_json }
    end
    context 'when it is unthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/contacts/chatwoot_embed/new"
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end
      it 'should redirect to new embed chatwoot page' do
        get("/accounts/#{account.id}/contacts/chatwoot_embed/new", params:)
        expect(response).to have_http_status(200)
        expect(response.body).to include('This contact does not exist in Woofed CRM. Would you like to create it?')
      end
    end
  end
  describe 'POST /accounts/{account.id}/contacts/chatwoot_embed' do
    context 'when it is unthenticated user' do
      it 'returns unauthorized' do
        post "/accounts/#{account.id}/contacts/chatwoot_embed", params: { contact: {} }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end
      context 'when the contact_params contains data for a non-existent contact' do
        let(:params) do
          { contact: { full_name: 'yukio', phone_number: '+55229988132',
                       email: 'non-existent_contact@email.com' } }
        end
        it 'should create a contact and redirect to show embed chatwoot page' do
          expect do
            post("/accounts/#{account.id}/contacts/chatwoot_embed", params:)
          end.to change(Contact, :count).by(1)
          expect(Contact.count).to eq(2)
          expect(response).to have_http_status(302)
          expect(response).to redirect_to(account_chatwoot_embed_path(account, last_contact))
          follow_redirect!
          expect(response.body).to include(last_contact.full_name)
          expect(response.body).to include(last_contact.email)
          expect(response.body).to include(last_contact.phone)
        end
      end
      pending 'when the contact_params contains data for an existing contact' do
        let(:params) do
          { contact: { full_name: contact.full_name, phone: contact.phone,
                       email: contact.email } }
        end
        it 'should not create a contact and return error' do
          expect do
            post("/accounts/#{account.id}/contacts/chatwoot_embed", params:)
          end.to change(Contact, :count).by(0)
          expect(Contact.count).to eq(1)
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end
end
