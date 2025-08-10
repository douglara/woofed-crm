require 'rails_helper'

RSpec.describe Accounts::UsersController, type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user) }
  let!(:es_user) { create(:user, :es_language) }
  let!(:another_user) do
    create(:user, full_name: 'Another User', email: 'another@example.com')
  end
  let(:user_mock) { instance_double(User) }

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

      it 'gets users by account' do
        get "/accounts/#{account.id}/users"
        expect(response.body).to include(user.email)
        expect(response).to have_http_status(:success)
        expect(flash[:error]).to be_nil
      end

      context 'when query params are present' do
        context 'when query params match with user full_name' do
          it 'returns users on users table' do
            get "/accounts/#{account.id}/users", params: { query: user.full_name }
            expect(response).to have_http_status(200)
            expect(response.body).to include('Users')
            doc = Nokogiri::HTML(response.body)
            table_body = doc.at_css('tbody#users__index_user').text
            expect(table_body).to include(ERB::Util.html_escape(user.full_name))
            expect(table_body).to include(user.email)
            expect(table_body).to include(user.phone)
          end
        end

        context 'when query params match with user email' do
          it 'returns users on users table' do
            get "/accounts/#{account.id}/users", params: { query: user.email }
            expect(response).to have_http_status(200)
            expect(response.body).to include('Users')
            doc = Nokogiri::HTML(response.body)
            table_body = doc.at_css('tbody#users__index_user').text
            expect(table_body).to include(ERB::Util.html_escape(user.full_name))
            expect(table_body).to include(user.email)
            expect(table_body).to include(user.phone)
          end
        end

        context 'when query params match with user phone' do
          it 'returns users on users table' do
            get "/accounts/#{account.id}/users", params: { query: user.phone }
            expect(response).to have_http_status(200)
            expect(response.body).to include('Users')
            doc = Nokogiri::HTML(response.body)
            table_body = doc.at_css('tbody#users__index_user').text
            expect(table_body).to include(ERB::Util.html_escape(user.full_name))
            expect(table_body).to include(user.email)
            expect(table_body).to include(user.phone)
          end
        end

        context 'when query params match partially with user full_name' do
          let(:first_name) { user.full_name.split.first }
          it 'returns users with partial match' do
            get "/accounts/#{account.id}/users", params: { query: first_name }
            expect(response).to have_http_status(200)
            expect(response.body).to include('Users')
            doc = Nokogiri::HTML(response.body)
            table_body = doc.at_css('tbody#users__index_user').text
            expect(table_body).to include(ERB::Util.html_escape(user.full_name))
            expect(table_body).to include(user.email)
            expect(table_body).to include(user.phone)
          end
        end

        context 'when query params are case-insensitive' do
          it 'returns users regardless of case' do
            get "/accounts/#{account.id}/users", params: { query: user.full_name.swapcase }
            expect(response).to have_http_status(200)
            expect(response.body).to include('Users')
            doc = Nokogiri::HTML(response.body)
            table_body = doc.at_css('tbody#users__index_user').text
            expect(table_body).to include(ERB::Util.html_escape(user.full_name))
            expect(table_body).to include(user.email)
            expect(table_body).to include(user.phone)
          end
        end

        context 'when query params do not match any users' do
          it 'returns an empty users table' do
            get "/accounts/#{account.id}/users", params: { query: 'Nonexistentuser123' }
            expect(response).to have_http_status(200)
            expect(response.body).to include('Users')
            doc = Nokogiri::HTML(response.body)
            table_body = doc.at_css('tbody#users__index_user').text
            expect(table_body).not_to include(ERB::Util.html_escape(user.full_name))
            expect(table_body).not_to include(user.email)
            expect(table_body).not_to include(user.phone)
          end
        end

        context 'when there are multiple users and query does not match any' do
          let!(:user2) do
            create(:user, full_name: 'Jane Smith', email: 'jane.smith@example.com',
                          phone: '+55226598745699')
          end
          let!(:user3) do
            create(:user, full_name: 'Bob Johnson', email: 'bob.johnson@example.com',
                          phone: '+5541225695285')
          end

          it 'returns an empty users table' do
            get "/accounts/#{account.id}/users", params: { query: 'Nonexistentuser123' }
            expect(response).to have_http_status(200)
            expect(response.body).to include('Users')
            doc = Nokogiri::HTML(response.body)
            table_body = doc.at_css('tbody#users__index_user').text
            expect(table_body).not_to include(ERB::Util.html_escape(user.full_name))
            expect(table_body).not_to include(ERB::Util.html_escape(user2.full_name))
            expect(table_body).not_to include(ERB::Util.html_escape(user3.full_name))
          end
        end
      end
    end
  end

  describe 'GET /accounts/{account.id}/users/new' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/users/new"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      it 'visits user new page (en)' do
        get "/accounts/#{account.id}/users/new"
        expect(response.body).to include('User data')
        expect(response).to have_http_status(:success)
        expect(flash[:error]).to be_nil
      end

      context 'with es language' do
        before do
          sign_in(es_user)
        end

        it 'visits user new page (es)' do
          get "/accounts/#{account.id}/users/new"
          expect(response.body).to include('Datos del usuario')
          expect(response).to have_http_status(:success)
          expect(flash[:error]).to be_nil
        end
      end
    end
  end

  describe 'GET /accounts/{account.id}/users/{user.id}/edit' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/users/#{user.id}/edit"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      context 'when editing self' do
        it 'allows access to edit self user' do
          get "/accounts/#{account.id}/users/#{user.id}/edit"
          expect(response).to have_http_status(:success)
          expect(response.body).to include(ERB::Util.html_escape(user.full_name))
          expect(flash[:error]).to be_nil
        end
      end

      context 'when editing another user' do
        it 'allows access to edit another user' do
          get "/accounts/#{account.id}/users/#{another_user.id}/edit"
          expect(response).to have_http_status(:success)
          expect(response.body).to include(ERB::Util.html_escape(another_user.full_name))
          expect(flash[:error]).to be_nil
        end
      end
    end
  end

  describe 'POST /accounts/{account.id}/users' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/accounts/#{account.id}/users", params: {}
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      let(:valid_params) do
        { user: { full_name: 'Yukio', email: 'yukio@email.com', password: '123456', password_confirmation: '123456',
                  phone: '+5522998813788' } }
      end
      before do
        sign_in(user)
      end

      it 'creates user successfully' do
        expect do
          post "/accounts/#{account.id}/users", params: valid_params
        end.to change(User, :count).by(1)
        expect(response).to redirect_to(account_users_path(account))
        expect(flash[:error]).to be_nil
      end

      context 'when email is invalid' do
        it 'when email is blank' do
          invalid_params = { user: { full_name: 'Yukio', email: '', password: '123456',
                                     password_confirmation: '123456' } }
          expect do
            post "/accounts/#{account.id}/users", params: invalid_params
          end.to change(User, :count).by(0)
          expect(response.body).to match(/Email can&#39;t be blank/)
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  describe 'PATCH /accounts/{account.id}/users/{user.id}' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch "/accounts/#{account.id}/users/#{user.id}"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      let(:valid_params) do
        { user: { full_name: 'Yukio Updated', email: 'yukio@email.com', password: '123456',
                  password_confirmation: '123456' } }
      end
      before do
        sign_in(user)
      end

      it 'updates user successfully' do
        patch "/accounts/#{account.id}/users/#{user.id}", params: valid_params
        expect(User.first.full_name).to eq('Yukio Updated')
        expect(response).to redirect_to(edit_account_user_path(account, user))
        expect(flash[:error]).to be_nil
      end

      context 'when updating another user' do
        it 'updates another user successfully' do
          patch "/accounts/#{account.id}/users/#{another_user.id}", params: valid_params
          expect(another_user.reload.full_name).to eq('Yukio Updated')
          expect(response).to redirect_to(edit_account_user_path(account, another_user))
          expect(flash[:error]).to be_nil
        end
        context 'when params is invalid' do
          it 'should return unprocessable_entity' do
            invalid_params = { user: { full_name: 'Yukio', email: 'yukio@email.com', password: '123',
                                       password_confirmation: '123' } }
            patch "/accounts/#{account.id}/users/#{user.id}",
                  params: invalid_params
            expect(response.body).to include('Password is too short (minimum is 6 characters)')
            expect(response).to have_http_status(:unprocessable_entity)
          end
        end
      end
    end
  end

  describe 'PATCH /accounts/{account.id}/users/{es_user.id}' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch "/accounts/#{account.id}/users/#{es_user.id}"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(es_user)
      end

      context 'when updating self with valid language' do
        let(:valid_params) { { user: { language: 'pt-BR' } } }

        it 'updates language and renders page in pt-BR' do
          patch "/accounts/#{account.id}/users/#{es_user.id}", params: valid_params
          expect(es_user.reload.language).to eq('pt-BR')
          follow_redirect!
          expect(response.body).to include('Nome Completo')
          expect(flash[:error]).to be_nil
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

      context 'when deleting self' do
        it 'deletes user successfully without requiring access_system_settings' do
          expect do
            delete "/accounts/#{account.id}/users/#{user.id}"
          end.to change(User, :count).by(-1)
          expect(response).to redirect_to(account_users_path(account))
          expect(flash[:notice]).to include('User was successfully destroyed.')
          expect(flash[:error]).to be_nil
        end
      end

      context 'when deleting another user' do
        it 'deletes another user successfully' do
          expect do
            delete "/accounts/#{account.id}/users/#{another_user.id}"
          end.to change(User, :count).by(-1)
          expect(response).to redirect_to(account_users_path(account))
          expect(flash[:notice]).to include('User was successfully destroyed.')
          expect(flash[:error]).to be_nil
        end
      end
    end
  end

  describe 'GET /accounts/{account.id}/users/select_user_search?query=query' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/users/select_user_search?query=query"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      context 'select user search component' do
        it 'renders search component' do
          get "/accounts/#{account.id}/users/select_user_search"
          expect(response).to have_http_status(:success)
        end

        context 'when there is query parameter' do
          it 'should return user' do
            get "/accounts/#{account.id}/users/select_user_search?query=#{user.full_name}"
            expect(response).to have_http_status(200)

            html = Nokogiri::HTML(response.body)
            user_list_frame = html.at_css('turbo-frame#select_user_results').text
            expect(user_list_frame).to include(user.full_name)
          end

          context 'when query parameter is not found' do
            it 'should return 0 users' do
              get "/accounts/#{account.id}/users/select_user_search", params: { query: 'testdsfsdf' }
              expect(response).to have_http_status(200)

              html = Nokogiri::HTML(response.body)
              user_list_frame = html.at_css('turbo-frame#select_user_results').text
              expect(user_list_frame).not_to include(user.full_name)
              expect(user_list_frame.strip.empty?).to be_truthy
            end
          end
        end

        context 'when there is a form_name parameter' do
          it 'should render form_name as hidden_field_name on html form' do
            get "/accounts/#{account.id}/users/select_user_search",
                params: { form_name: 'deal[user_id]' }

            expect(response).to have_http_status(200)
            expect(response.body).to include('deal[user_id]')
          end
        end

        context 'when there is no form_name parameter' do
          it 'should not render a specific hidden_field_name on html form' do
            get "/accounts/#{account.id}/users/select_user_search"

            expect(response).to have_http_status(200)
            expect(response.body).not_to include('deal[user_id]')
          end
        end

        context 'when there is a content_value parameter' do
          it 'should render content_value as selected_model_name on html form' do
            get "/accounts/#{account.id}/users/select_user_search",
                params: { content_value: 'user_name_test' }

            expect(response).to have_http_status(200)
            expect(response.body).to include('user_name_test')
            expect(response.body).not_to include('Search user')
          end
        end

        context 'when there is no content_value parameter' do
          it 'should render the default search placeholder instead of a selected name' do
            get "/accounts/#{account.id}/users/select_user_search"

            expect(response).to have_http_status(200)
            expect(response.body).not_to include('user_name_test')
            expect(response.body).to include('Search user')
          end
        end

        context 'when there is a form_id parameter' do
          it 'should render form_id as hidden_field_value on html form' do
            get "/accounts/#{account.id}/users/select_user_search",
                params: { form_id: '101563597' }

            expect(response).to have_http_status(200)
            expect(response.body).to include('value="101563597"')
          end
        end

        context 'when there is no form_id parameter' do
          it 'should not render a specific id in the hidden field' do
            get "/accounts/#{account.id}/users/select_user_search"
            expect(response).to have_http_status(200)
            expect(response.body).not_to include('value="101563597"')
          end
        end

        context 'when all parameters are present' do
          it 'should render all parameters correctly in the HTML form' do
            get "/accounts/#{account.id}/users/select_user_search",
                params: {
                  form_name: 'deal_assignee[user_id]',
                  content_value: 'user_name_test',
                  form_id: '101'
                }

            expect(response).to have_http_status(200)
            expect(response.body).to include('deal_assignee[user_id]')
            expect(response.body).to include('user_name_test')
            expect(response.body).to include('value="101"')
            expect(response.body).not_to include('Search user')
          end
        end
      end
    end
  end
  describe 'GET /accounts/{account.id}/users/{user.id}/hovercard_preview' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/users/#{user.id}/hovercard_preview"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      it 'get user hovercard preview by account' do
        get "/accounts/#{account.id}/users/#{user.id}/hovercard_preview"
        expect(response.body).to include(ERB::Util.html_escape(user.full_name))
        expect(response.body).to include(ERB::Util.html_escape(user.email))
        expect(response.body).to include(ERB::Util.html_escape(user.phone))
        expect(response.body).to include("hovercard_preview_user_#{user.id}")
      end
    end
  end
end
