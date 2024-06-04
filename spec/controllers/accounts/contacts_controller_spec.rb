require 'rails_helper'

RSpec.describe Accounts::ContactsController, type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:contact) { create(:contact, account: account) }

  context 'when it is an unauthenticated user' do
    let!(:params) do
      { contact: { full_name: 'Yukio Arie', email: 'yukioarie@gmail.com', phone: '+5522998813788',
                   account_id: account.id } }
    end

    it 'returns unauthorized' do
      expect { post "/accounts/#{account.id}/contacts", params: params }.not_to change(Contact, :count)
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  context 'POST #create' do
    before do
      sign_in(user)
    end

    let!(:params) do
      { contact: { full_name: 'Yukio Arie', email: 'yukioarie@gmail.com', phone: '+5522998813788',
                   account_id: account.id } }
    end

    it 'create contact' do
      expect do
        post "/accounts/#{account.id}/contacts", params: params
      end.to change(Contact, :count).by(1)

      expect(response).to have_http_status(302)
    end

    context 'not create a new contact' do
      it 'when full_name is blank' do
        params = { contact: { full_name: '', email: 'yukioarie@gmail.com', phone: '+5522998813788',
                              account_id: account.id } }

        expect do
          post "/accounts/#{account.id}/contacts", params: params
        end.to change(Contact, :count).by(0)

        expect(response.body).to match(/Name can&#39;t be blank/)
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'when full_name is nil' do
        params = { contact: { full_name: nil, email: 'yukioarie@gmail.com', phone: '+5522998813788',
                              account_id: account.id } }

        expect do
          post "/accounts/#{account.id}/contacts", params: params
        end.to change(Contact, :count).by(0)

        expect(response.body).to match(/Name can&#39;t be blank/)
        expect(response).to have_http_status(:unprocessable_entity)
      end

      context 'when phone is invalid' do
        it 'when phone is more than 15 characters' do
          params = { contact: { full_name: 'Yukio Arie', email: 'yukioarie@gmail.com', phone: '+552299881378888889',
                                account_id: account.id } }

          expect do
            post "/accounts/#{account.id}/contacts", params: params
          end.to change(Contact, :count).by(0)

          expect(response.body).to include('Phone (cell) is invalid')
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'when phone starts with +0' do
          params = { contact: { full_name: 'Yukio Arie', email: 'yukioarie@gmail.com', phone: '+052299881378888889',
                                account_id: account.id } }

          expect do
            post "/accounts/#{account.id}/contacts", params: params
          end.to change(Contact, :count).by(0)

          expect(response.body).to include('Phone (cell) is invalid')
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'when phone doesnt start with +' do
          params = { contact: { full_name: 'Yukio Arie', email: 'yukioarie@gmail.com', phone: '052299881378888889',
                                account_id: account.id } }

          expect do
            post "/accounts/#{account.id}/contacts", params: params
          end.to change(Contact, :count).by(0)

          expect(response.body).to include('Phone (cell) is invalid')
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  context 'GET #show' do
    before do
      sign_in(user)
    end

    it 'should list contacts' do
      get "/accounts/#{account.id}/contacts"
      expect(response).to have_http_status(200)
      expect(response.body).to include(contact.full_name)
    end
  end

  describe 'GET /accounts/{account.id}/contacts/select_contact_search?query=query' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/contacts/select_contact_search?query=query"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end
      context 'select contact search component' do
        it do
          get "/accounts/#{account.id}/contacts/select_contact_search"
          expect(response).to have_http_status(200)
        end
        context 'when there is query parameter' do
          it 'should return product' do
            get "/accounts/#{account.id}/contacts/select_contact_search?query=#{contact.full_name}"
            expect(response).to have_http_status(200)
            expect(response.body).to include(contact.full_name)
          end
          context 'when query paramenter is not founded' do
            it 'should return 0 products' do
              get "/accounts/#{account.id}/contacts/select_contact_search?query=teste"
              expect(response).to have_http_status(200)
              expect(response.body).not_to include('teste')
              expect(response.body).not_to include(contact.full_name)
            end
          end
        end
      end
    end
  end
end
