require 'rails_helper'

RSpec.describe Devise::SessionsController, type: :request do
  let(:user) { create(:user) }
  let(:account) { create(:account) }
  let(:valid_params) do
    {
      user: {
        email: 'yukio@email.com',
        password: '123456',
        password_confirmation: '123456',
        phone: '+5522998813788',
        account_attributes: {
          name: 'woofed'
        }
      }
    }
  end

  describe 'POST /users' do
    context 'success' do
      it 'should create a new user' do
        expect do
          post '/users',
               params: valid_params
        end.to change(User, :count).by(1)
        expect(response).to redirect_to(root_path)
      end
    end
    context 'failed' do
      it 'email users already registered' do
        user
        invalid_params = valid_params.deep_merge(user: { email: user.email  })
        expect do
          post '/users',
               params: invalid_params
        end.to change(User, :count).by(0)
        expect(response.body).to include('E-mail já está em uso')
      end
      it 'create users without account' do
        invalid_params = valid_params[:user].except(:account_attributes)
        expect do
          post '/users',
               params: invalid_params
        end.to change(User, :count).by(0)
        expect(response.body).to include('Account é obrigatório(a)')
      end
      it 'if password confirmation is different than password' do
        invalid_params = valid_params.deep_merge(user: { password: '123456789'  })
        expect do
          post '/users',
               params: invalid_params
        end.to change(User, :count).by(0)
        expect(response.body).to include('Confirme sua Senha não é igual a Senha')
      end
      it 'if phone is invalid' do
        invalid_params = valid_params.deep_merge(user: { phone: '123456789'  })
        expect do
          post '/users',
               params: invalid_params
        end.to change(User, :count).by(0)
        expect(response.body).to include('Telefone (celular) Número inválido')
      end
    end
  end
end
