require 'rails_helper'

RSpec.describe Accounts::UsersController, type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }

  describe 'POST /accounts/{account.id}/users' do
    let(:valid_params) do
      { user: { full_name: 'Yukio', email: 'yukio@email.com', password: '123456', password_confirmation: '123456',
                phone: '+5522998813788' } }
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/accounts/#{account.id}/users"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      context 'create user' do
        it do
          expect do
            post "/accounts/#{account.id}/users",
                 params: valid_params
          end.to change(User, :count).by(1)
          expect(response).to redirect_to(account_users_path(account))
        end
        context 'when email is invalid' do
          it 'when email is blank' do
            invalid_params = { user: { full_name: 'Yukio', email: '', password: '123456',
                                       password_confirmation: '123456' } }
            expect do
              post "/accounts/#{account.id}/users",
                   params: invalid_params
            end.to change(User, :count).by(0)
            expect(response.body).to match(/Email can&#39;t be blank/)
            expect(response).to have_http_status(:unprocessable_entity)
          end
          it 'when email is incorrect' do
            invalid_params = { user: { full_name: 'Yukio', email: 'email invalido', password: '123456',
                                       password_confirmation: '123456' } }
            expect do
              post "/accounts/#{account.id}/users",
                   params: invalid_params
            end.to change(User, :count).by(0)
            expect(response.body).to include('Email is invalid')
            expect(response).to have_http_status(:unprocessable_entity)
          end
        end

        context 'when password is invalid' do
          it 'when password is blank' do
            invalid_params = { user: { full_name: 'Yukio', email: 'yukio@email.com', password: '',
                                       password_confirmation: '' } }
            expect do
              post "/accounts/#{account.id}/users",
                   params: invalid_params
            end.to change(User, :count).by(0)
            expect(response.body).to match(/Password can&#39;t be blank/)
            expect(response).to have_http_status(:unprocessable_entity)
          end
          it 'when password have less 6 characters' do
            invalid_params = { user: { full_name: 'Yukio', email: 'yukio@email.com', password: '123',
                                       password_confirmation: '123' } }
            expect do
              post "/accounts/#{account.id}/users",
                   params: invalid_params
            end.to change(User, :count).by(0)
            expect(response.body).to include('Password is too short (minimum is 6 characters)')
            expect(response).to have_http_status(:unprocessable_entity)
          end
          it 'when password and password_confirmation is diferent' do
            invalid_params = { user: { full_name: 'Yukio', email: 'yukio@email.com', password: '123',
                                       password_confirmation: '456' } }
            expect do
              post "/accounts/#{account.id}/users",
                   params: invalid_params
            end.to change(User, :count).by(0)
            expect(response.body).to match(/Confirm your password doesn&#39;t match Password/)
            expect(response).to have_http_status(:unprocessable_entity)
          end
        end
        it 'when user exists' do
          invalid_params = { user: { full_name: 'dsada', email: user.email, password: '123456',
                                     password_confirmation: '123456' } }
          expect do
            post "/accounts/#{account.id}/users",
                 params: invalid_params
          end.to change(User, :count).by(0)
          expect(response.body).to include('Email has already been taken')
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end
  describe 'GET /accounts/{account.id}/users' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/users"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      context 'get users' do
        it do
          get "/accounts/#{account.id}/users"
          expect(response.body).to include('belchior@show.com.br')
          expect(response).to have_http_status(200)
        end
        it 'get users by account' do
          account_2 = create(:account, name: 'account teste')
          create(:user, full_name: 'Yukio', email: 'yukio@email.com', password: '123456',
                        password_confirmation: '123456', account_id: account_2.id)
          get "/accounts/#{account.id}/users"
          expect(response.body).to include('belchior@show.com.br')
          expect(account.users.count).to eq(1)
        end
      end
    end
  end
  describe 'PACTH /accounts/{account.id}/users/{user.id}' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch "/accounts/#{account.id}/users/#{user.id}"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      context 'update user' do
        let(:valid_params) do
          { user: { full_name: 'Yukio Updated', email: 'yukio@email.com', password: '123456',
                    password_confirmation: '123456' } }
        end
        it do
          patch "/accounts/#{account.id}/users/#{user.id}", params: valid_params
          expect(User.first.full_name).to eq('Yukio Updated')
          expect(response.body).to redirect_to(edit_account_user_path(account.id, user.id))
        end
        context 'when email is invalid' do
          it 'when email is blank' do
            invalid_params = { user: { full_name: 'Yukio', email: '', password: '123456',
                                       password_confirmation: '123456' } }

            patch "/accounts/#{account.id}/users/#{user.id}",
                  params: invalid_params
            expect(User.first.email).to eq('belchior@show.com.br')
            expect(response.body).to match(/Email can&#39;t be blank/)
            expect(response).to have_http_status(:unprocessable_entity)
          end
          it 'when email is incorrect' do
            invalid_params = { user: { full_name: 'Yukio', email: 'email invalido', password: '123456',
                                       password_confirmation: '123456' } }
            patch "/accounts/#{account.id}/users/#{user.id}",
                  params: invalid_params
            expect(User.first.email).to eq('belchior@show.com.br')
            expect(response.body).to include('Email is invalid')
            expect(response).to have_http_status(:unprocessable_entity)
          end
        end
        it 'when password is blank' do
          params = { user: { full_name: 'Yukio Updated', email: 'yukio@email.com', password: '',
                             password_confirmation: '' } }
          patch "/accounts/#{account.id}/users/#{user.id}",
                params: params
          expect(User.first.full_name).to eq('Yukio Updated')
          expect(response).to redirect_to(edit_account_user_path(account.id, user.id))
        end

        context 'when password is invalid' do
          it 'when password have less 6 characters' do
            invalid_params = { user: { full_name: 'Yukio', email: 'yukio@email.com', password: '123',
                                       password_confirmation: '123' } }
            patch "/accounts/#{account.id}/users/#{user.id}",
                  params: invalid_params

            expect(response.body).to include('Password is too short (minimum is 6 characters)')
            expect(response).to have_http_status(:unprocessable_entity)
          end
          it 'when password and password_confirmation is diferent' do
            invalid_params = { user: { full_name: 'Yukio', email: 'yukio@email.com', password: '123',
                                       password_confirmation: '456' } }

            patch "/accounts/#{account.id}/users/#{user.id}",
                  params: invalid_params

            expect(response.body).to match(/Confirm your password doesn&#39;t match Password/)
            expect(response).to have_http_status(:unprocessable_entity)
          end
        end
      end
    end
  end
  describe 'DELETE /accounts/{account.id}/users/{user.id}' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/accounts/#{account.id}/users/#{user.id}"
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end
      context 'delete the user' do
        it do
          delete "/accounts/#{account.id}/users/#{user.id}"
          expect(User.count).to eq(0)
          expect(response.status).to eq(204)
        end
      end
    end
  end
end
