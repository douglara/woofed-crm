require 'rails_helper'

RSpec.describe Devise::PasswordsController, type: :request do
  let(:user) { create(:user) }

  before { ActionMailer::Base.deliveries.clear }

  describe 'GET /users/password/new' do
    it 'renders the forgot password page' do
      get '/users/password/new'
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Forgot your password?')
    end
  end

  describe 'POST /users/password' do
    context 'with a registered email' do
      it 'sends a reset password email, redirects to sign in and delivers to the correct address' do
        expect do
          post '/users/password', params: { user: { email: user.email } }
        end.to change(ActionMailer::Base.deliveries, :count).by(1)

        expect(response).to redirect_to(new_user_session_path)
        expect(ActionMailer::Base.deliveries.last.to).to include(user.email)
      end
    end

    context 'with an unregistered email' do
      it 'does not send an email' do
        expect do
          post '/users/password', params: { user: { email: 'nonexistent@example.com' } }
        end.not_to change(ActionMailer::Base.deliveries, :count)
      end
    end
  end

  describe 'GET /users/password/edit' do
    let(:token) { user.send_reset_password_instructions }

    it 'renders the change password form with a valid token' do
      get "/users/password/edit?reset_password_token=#{token}"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Set new password')
    end
  end

  describe 'PUT /users/password' do
    let(:token) { user.send_reset_password_instructions }

    context 'with valid params' do
      it 'changes the password and redirects' do
        put '/users/password', params: {
          user: {
            reset_password_token: token,
            password: 'NewPassword1!',
            password_confirmation: 'NewPassword1!'
          }
        }
        expect(response).to redirect_to(root_path)
        expect(user.reload.valid_password?('NewPassword1!')).to be true
      end
    end

    context 'with mismatching passwords' do
      it 'does not change the password' do
        put '/users/password', params: {
          user: {
            reset_password_token: token,
            password: 'NewPassword1!',
            password_confirmation: 'DifferentPassword!'
          }
        }
        expect(user.reload.valid_password?('NewPassword1!')).to be false
      end
    end

    context 'with an expired token' do
      it 'does not change the password' do
        token # force evaluation before time travel
        travel_to(7.hours.from_now) do
          put '/users/password', params: {
            user: {
              reset_password_token: token,
              password: 'NewPassword1!',
              password_confirmation: 'NewPassword1!'
            }
          }
          expect(user.reload.valid_password?('NewPassword1!')).to be false
        end
      end
    end
  end
end
