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

        expect(response.body).to include('Nome completo não pode ficar em branco')
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'when full_name is nil' do
        params = { contact: { full_name: nil, email: 'yukioarie@gmail.com', phone: '+5522998813788',
                              account_id: account.id } }

        expect do
          post "/accounts/#{account.id}/contacts", params: params
        end.to change(Contact, :count).by(0)

        expect(response.body).to include('Nome completo não pode ficar em branco')
        expect(response).to have_http_status(:unprocessable_entity)
      end

      context 'when phone is invalid' do
        it 'when phone is more than 15 characters' do
          params = { contact: { full_name: 'Yukio Arie', email: 'yukioarie@gmail.com', phone: '+552299881378888889',
                                account_id: account.id } }

          expect do
            post "/accounts/#{account.id}/contacts", params: params
          end.to change(Contact, :count).by(0)

          expect(response.body).to include('Telefone (celular) Número inválido')
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'when phone starts with +0' do
          params = { contact: { full_name: 'Yukio Arie', email: 'yukioarie@gmail.com', phone: '+052299881378888889',
                                account_id: account.id } }

          expect do
            post "/accounts/#{account.id}/contacts", params: params
          end.to change(Contact, :count).by(0)

          expect(response.body).to include('Telefone (celular) Número inválido')
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'when phone doesnt start with +' do
          params = { contact: { full_name: 'Yukio Arie', email: 'yukioarie@gmail.com', phone: '052299881378888889',
                                account_id: account.id } }

          expect do
            post "/accounts/#{account.id}/contacts", params: params
          end.to change(Contact, :count).by(0)

          expect(response.body).to include('Telefone (celular) Número inválido')
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  context 'GET #new' do
    before do
      sign_in(user)
    end

    it 'create a new contact' do
      get "/accounts/#{account.id}/contacts"
      expect(response).to have_http_status(200)
    end
  end

  #   context "DELETE #destroy" do
  #     before do
  #       sign_in(user)
  #     end
  #     it "destroy a contact" do
  #       expect do
  #         delete "/accounts/#{account.id}/contacts/#{contact.id}"
  #       end.to change(Contact, :count).by(-1)
  #       expect(Contact.find_by(id: contact.id)).to be_nil
  #       expect(response).to have_http_status(302)
  #     end
  #   end
end
