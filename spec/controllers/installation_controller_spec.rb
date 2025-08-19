require 'rails_helper'

RSpec.describe InstallationController, type: :request do
  let(:first_user) { User.first }
  let(:last_user) { User.last }
  let(:first_installation) { Installation.first }
  let(:first_account) { Account.first }

  before(:each) do
    Installation.delete_all
    load "#{Rails.root}/app/controllers/application_controller.rb"
    Rails.application.reload_routes!
  end

  after(:each) do
    load "#{Rails.root}/app/controllers/application_controller.rb"
    Rails.application.reload_routes!
  end

  describe 'GET /installation/create' do
    context 'when it is an unauthenticated user' do
      context 'when there are valid params' do
        it 'should create user and installation and redirect to step_1 path' do
          expect do
            get '/installation/create',
                params: { user: { email: 'yukioteste@email.com', full_name: 'Yukio teste' },
                          installation: { id: 1, key1: 'key1teste', key2: 'key2teste', token: 'tokenteste' } }
          end.to change(Installation, :count).by(1)
                                             .and change(User, :count).by(1)
          expect(response).to redirect_to(installation_step_1_path)
          expect(first_user.full_name).to eq('Yukio teste')
          expect(first_user.email).to eq('yukioteste@email.com')
          expect(first_installation.id).to eq('1')
          expect(first_installation.key1).to eq('key1teste')
          expect(first_installation.key2).to eq('key2teste')
          expect(first_installation.token).to eq('tokenteste')
        end
      end
      context 'when there are invalid params' do
        context 'when user params is invalid' do
          it 'should not create user and installation and render new action installation controller' do
            expect do
              get '/installation/create',
                  params: { user: { email: '', full_name: 'Yukio teste', phone: '@dsad55' },
                            installation: { id: 1, key1: 'key1teste', key2: 'key2teste', token: 'tokenteste' } }
            end.to change(Installation, :count).by(0)
                                               .and change(User, :count).by(0)
            expect(response).to have_http_status(:unprocessable_entity)
          end
        end
        context 'when installation params is invalid' do
          context 'when there is no installation params' do
            it 'should not create installation and installation and render new action installation controller' do
              expect do
                get '/installation/create',
                    params: {
                      user: { email: 'yukio@email.com', full_name: 'Yukio teste' }
                    }
              end.to change(Installation, :count).by(0)
                                                 .and change(User, :count).by(0)
              expect(response).to have_http_status(:unprocessable_entity)
            end
          end
        end
      end

      context 'when account and user already exists' do
        let!(:account) { create(:account) }
        let!(:user) { create(:user, account:, full_name: 'Douglas') }
        it 'should update user and create a new installation and redirect to step_1' do
          params = { user: { email: user.email, full_name: 'Yukio teste' },
                     installation: { id: 1, key1: 'key1teste', key2: 'key2teste', token: 'tokenteste' } }
          expect do
            get '/installation/create',
                params:
          end.to change(Installation, :count).by(1)
                                             .and change(User, :count).by(0)
          expect(response).to have_http_status(302)
          expect(response).to redirect_to(installation_step_1_path)
          expect(user.reload.email).to eq(params[:user][:email])
          expect(user.full_name).to eq(params[:user][:full_name])
          expect(user.valid_password?('Password1!')).to be_falsey
        end
      end
      context 'when there is an installation' do
        context 'when installation status is completed' do
          let!(:installation) { create(:installation, status: 'completed') }

          it 'should not create user and installation and raise route error' do
            first_installation.app_reload
            get '/installation/create',
                params: { user: { email: 'yukio@email.com', full_name: 'Yukio teste' },
                          installation: { id: 1, key1: 'key1teste', key2: 'key2teste', token: 'tokenteste' } }
            expect(response).to have_http_status(:not_found)
          end
        end
        context 'when installation status is in_progress' do
          let!(:installation) { create(:installation, status: 'in_progress') }
          it 'should create user, update installation and redirect to step_1 path' do
            expect do
              get '/installation/create',
                  params: { user: { email: 'yukioteste@email.com', full_name: 'Yukio teste' },
                            installation: { id: '1', key1: 'key1teste', key2: 'key2teste', token: 'tokenteste' } }
            end.to change(Installation, :count).by(0)
                                               .and change(User, :count).by(1)
            expect(response).to redirect_to(installation_step_1_path)
            expect(last_user.full_name).to eq('Yukio teste')
            expect(last_user.email).to eq('yukioteste@email.com')
            expect(last_user.installation.token).to eq(first_installation.token)
            expect(first_installation.id).to eq('1')
            expect(first_installation.key1).to eq('key1teste')
            expect(first_installation.key2).to eq('key2teste')
            expect(first_installation.token).to eq('tokenteste')
          end
        end
      end
    end

    context 'when it is an authenticated user' do
      let!(:account) { create(:account) }
      let!(:user) { create(:user, account:) }

      before do
        sign_in(user)
      end

      context 'when there is no installation' do
        it 'should create user and installation and redirect to step_1' do
          params = { user: { email: 'yukio@email.com', full_name: 'Yukio teste' },
                     installation: { id: 1, key1: 'key1teste', key2: 'key2teste', token: 'tokenteste' } }
          expect do
            get '/installation/create',
                params:
          end.to change(Installation, :count).by(1)
                                             .and change(User, :count).by(1)
          expect(response).to redirect_to(installation_step_1_path)
          expect(last_user.full_name).to eq(params[:user][:full_name])
          expect(last_user.email).to eq(params[:user][:email])
        end
      end
      context 'when there is an installation' do
        context 'when installation status is completed' do
          let!(:installation) { create(:installation, status: 'completed') }
          it 'should not create user and installation and raise route error' do
            first_installation.app_reload
            get '/installation/create',
                params: { user: { email: 'yukio@email.com', full_name: 'Yukio teste' },
                          installation: { id: 1, key1: 'key1teste', key2: 'key2teste', token: 'tokenteste' } }
            expect(response).to have_http_status(:not_found)
          end
        end
        context 'when installation status is in_progress' do
          let!(:installation) { create(:installation, status: 'in_progress') }
          it 'should create user, update installation and redirect to step_1' do
            expect do
              get '/installation/create',
                  params: { user: { email: 'yukio@email.com', full_name: 'Yukio teste' },
                            installation: { id: 1, key1: 'key1teste', key2: 'key2teste', token: 'tokenteste' } }
            end.to change(Installation, :count).by(0)
                                               .and change(User, :count).by(1)
            expect(response).to redirect_to(installation_step_1_path)
            expect(last_user.full_name).to eq('Yukio teste')
            expect(last_user.email).to eq('yukio@email.com')
            expect(first_installation.id).to eq('1')
            expect(first_installation.key1).to eq('key1teste')
            expect(first_installation.key2).to eq('key2teste')
            expect(first_installation.token).to eq('tokenteste')
          end
        end
      end
    end
  end

  describe 'setup_installation' do
    context 'GET /accounts/1/users' do
      skip 'when there is no user and installation registered' do
        it 'should redirect to installation new path' do
          get '/accounts/1/users'
          expect(response).to redirect_to(installation_new_path)
        end
      end

      context 'when it is an unauthenticated user' do
        let!(:account) { create(:account) }
        let!(:user) { create(:user, account:) }
        context 'when there is an instalation' do
          context 'when installation status is completed' do
            let!(:installation) { create(:installation, status: 'completed') }

            it 'should redirect to new devise sign in path' do
              get '/accounts/1/users'
              expect(response).to have_http_status(302)
              expect(response).to redirect_to(new_user_session_path)
            end
          end
          skip 'when installation status is in_progress' do
            let!(:installation) { create(:installation, status: 'in_progress') }

            it 'should redirect to new installation path' do
              get '/accounts/1/users'
              expect(response).to have_http_status(302)
              expect(response).to redirect_to(installation_new_path)
            end
          end
        end
      end

      context 'when it is authenticated user' do
        let!(:account) { create(:account) }
        let!(:user) { create(:user, account:) }
        before do
          sign_in user
        end
        it 'should redirect to new installation url' do
          get '/accounts/1/users'
          expect(response).to have_http_status(302)
          expect(response).to redirect_to(installation_new_path)
        end

        context 'when there is an installation' do
          context 'when installation status is completed' do
            let!(:installation) { create(:installation, status: 'completed') }

            it 'should get users url' do
              get '/accounts/1/users'
              expect(response).to have_http_status(200)
              expect(response.body).to include('Users')
            end
          end

          context 'when installation status is in_progress' do
            let!(:installation) { create(:installation, status: 'in_progress') }

            it 'should redirect to new installation url' do
              get '/accounts/1/users'
              expect(response).to have_http_status(302)
              expect(response).to redirect_to(installation_new_path)
            end
          end
        end
      end
    end
  end

  context 'GET /installation/new' do
    context 'when it is an unauthenticated user' do
      it 'should get new installation url' do
        get '/installation/new'
        expect(response).to have_http_status(200)
        expect(response.body).to include('Log in with')
        expect(response.body).to include('You are one step away from your company growing.')
      end
      context 'when there is an installation' do
        context 'when installation status is completed' do
          let!(:installation) { create(:installation, status: 'completed') }
          it 'should raise route error' do
            first_installation.app_reload
            get '/installation/new'
            expect(response).to have_http_status(:not_found)
          end
        end
        context 'when installation status is in_progress' do
          let!(:installation) { create(:installation, status: 'in_progress') }
          it 'should get new installation url' do
            get '/installation/new'
            expect(response).to have_http_status(200)
            expect(response.body).to include('Log in with')
            expect(response.body).to include('You are one step away from your company growing.')
          end
        end
      end
    end
    context 'when it is an authenticated user' do
      let!(:account) { create(:account) }
      let!(:user) { create(:user, account:) }

      before do
        sign_in user
      end

      it 'should get new installation url' do
        get '/installation/new'
        expect(response).to have_http_status(200)
        expect(response.body).to include('Log in with')
        expect(response.body).to include('You are one step away from your company growing.')
      end
    end
  end

  context 'GET /installation/step_1' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get '/installation/step_1'
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    context 'when it is an authenticated user' do
      let!(:account) { create(:account) }
      let!(:user) { create(:user, account:) }

      before do
        sign_in user
      end

      it 'should get step_1 installation url' do
        get '/installation/step_1'
        expect(response).to have_http_status(200)
        expect(response.body).to include('Basic Info')
        expect(response.body).to include('full name')
      end
      context 'when there is an installation' do
        context 'when installation status is completed' do
          let!(:installation) { create(:installation, status: 'completed') }
          it 'should raise route error' do
            first_installation.app_reload
            get '/installation/step_1'
            expect(response).to have_http_status(:not_found)
          end
        end
        context 'when installation status is in_progress' do
          let!(:installation) { create(:installation, status: 'in_progress') }
          it 'should get step_1 installation url' do
            get '/installation/step_1'
            expect(response).to have_http_status(200)
            expect(response.body).to include('Basic Info')
            expect(response.body).to include('full name')
          end
        end
      end
    end
  end

  describe 'PATCH /installation/update_step_1' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch '/installation/update_step_1', params: { user: { full_name: 'Yukio', phone: '+552299887875' } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    context 'when it is an authenticated user' do
      let!(:account) { create(:account) }
      let!(:user) { create(:user, account:) }

      before do
        sign_in user
      end

      it 'should update user and redirect to step 2 installation path' do
        expect do
          patch '/installation/update_step_1', params: { user: { full_name: 'Yukio', phone: '+552299887875' } }
        end.to change(User, :count).by(0)
        expect(response).to have_http_status(302)
        expect(response).to redirect_to(installation_step_2_path)
        expect(first_user.reload.full_name).to eq('Yukio')
        expect(first_user.phone).to eq('+552299887875')
      end
      context 'when there are invalid params' do
        it 'should not update user and raise error' do
          expect do
            patch '/installation/update_step_1', params: { user: { full_name: '', phone: '123456' } }
          end.to change(User, :count).by(0)
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include('Phone (cell) is invalid')
        end
      end

      context 'when there is installation' do
        context 'when installation status is completed' do
          let!(:installation) { create(:installation, status: 'completed') }
          it 'should raise route error' do
            first_installation.app_reload
            patch '/installation/update_step_1', params: { user: { full_name: 'Yukio', phone: '+552299887875' } }
            expect(response).to have_http_status(:not_found)
            expect(user.reload.full_name).not_to eq('Yukio')
          end
        end
        context 'when installation status is in_progress' do
          let(:installation) { create(:installation, status: 'in_progress') }
          it 'should update user and redirect to step 2 installation path' do
            patch '/installation/update_step_1', params: { user: { full_name: 'Yukio', phone: '+552299887875' } }
            expect(response).to have_http_status(302)
            expect(response).to redirect_to(installation_step_2_path)
            expect(first_user.reload.full_name).to eq('Yukio')
            expect(first_user.phone).to eq('+552299887875')
          end
        end
      end
    end
  end

  describe 'GET /installation/step_2' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get '/installation/step_2'
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    context 'when it is an authenticated user' do
      let!(:account) { create(:account) }
      let!(:user) { create(:user, account:) }

      before do
        sign_in user
      end

      it 'should get step_2 installation url' do
        get '/installation/step_2'
        expect(response).to have_http_status(200)
        expect(response.body).to include('Password')
        expect(response.body).to include('Confirm your password')
      end
    end
  end

  describe 'PATCH /installation/update_step_2' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch '/installation/update_step_2', params: { user: { password: '123456', password_confirmation: '123456' } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    context 'when it is an authenticated user' do
      let!(:account) { create(:account) }
      let!(:user) { create(:user, account:) }

      before do
        sign_in user
      end

      it 'should update user and redirect to step 3 installation path' do
        expect do
          patch '/installation/update_step_2', params: { user: { password: '123456', password_confirmation: '123456' } }
        end.to change(User, :count).by(0)
        expect(response).to have_http_status(302)
        expect(response).to redirect_to(installation_step_3_path)
      end
      context 'when there are invalid params' do
        it 'should not update user and raise error' do
          expect do
            patch '/installation/update_step_2',
                  params: { user: { password: '123456', password_confirmation: '123456789' } }
          end.to change(User, :count).by(0)
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to match(/Confirm your password doesn&#39;t match Password/)
        end
      end
    end
  end

  describe 'GET /installation/step_3' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get '/installation/step_3'
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    context 'when it is an authenticated user' do
      let!(:user) { create(:user) }

      before do
        sign_in user
      end

      it 'should get step_3 installation url' do
        get '/installation/step_3'
        expect(response).to have_http_status(200)
        expect(response.body).to include('Company Info')
        expect(response.body).to include('Company Site')
        expect(response.body).to include('Segment')
        expect(response.body).to include('Company Size')
        expect(response.body).to include('USD')
      end
      context 'when an account is already registered' do
        let!(:account) { create(:account) }
        it 'should include account infos' do
          get '/installation/step_3'
          expect(response).to have_http_status(200)
          expect(response.body).to include(account.name)
        end
      end
    end
  end
  describe 'PATCH /installation/update_step_3' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch '/installation/update_step_3',
              params: { account: { name: 'Woofed company', site_url: 'app.woofedcrm.com' } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    context 'when it is an authenticated user' do
      let!(:user) { create(:user) }

      before do
        sign_in user
      end
      context 'when an account is already registered' do
        let!(:account) { create(:account) }

        it 'should update account and redirect to loading installation path' do
          expect do
            patch '/installation/update_step_3',
                  params: { account: { name: 'Woofed company', site_url: 'app.woofedcrm.com', currency_code: 'USD' } }
          end.to change(Account, :count).by(0)
          expect(response).to have_http_status(302)
          expect(response).to redirect_to(installation_loading_path)
          expect(first_account.name).to eq('Woofed company')
          expect(first_account.site_url).to eq('https://app.woofedcrm.com')
          expect(first_account.currency_code).to eq('USD')
        end
        context 'when there are invalid params' do
          it 'should not update account and raise error' do
            expect do
              patch '/installation/update_step_3',
                    params: { account: { name: '', site_url: '' } }
            end.to change(Account, :count).by(0)
            expect(response).to have_http_status(:unprocessable_entity)
            expect(response.body).to match(/Name can&#39;t be blank/)
          end
        end
      end
      context 'when there is no account registered' do
        it 'should create account and redirect to loading installation path' do
          allow(Accounts::Create::EmbedCompanySiteJob).to receive(:perform_later).and_return(true)
          expect do
            patch '/installation/update_step_3',
                  params: { account: { name: 'Woofed company', site_url: 'https://url_test_update.com' } }
          end.to change(Account, :count).by(1)
          expect(response).to have_http_status(302)
          expect(response).to redirect_to(installation_loading_path)
          expect(first_account.name).to eq('Woofed company')
          expect(first_account.site_url).to eq('https://url_test_update.com')
        end
        context 'when there are invalid params' do
          it 'should not update account and raise error' do
            expect do
              patch '/installation/update_step_3',
                    params: { account: { name: '', site_url: '' } }
            end.to change(Account, :count).by(0)
            expect(response).to have_http_status(:unprocessable_entity)
            expect(response.body).to match(/Name can&#39;t be blank/)
          end
        end
      end
    end
  end
  describe 'GET installation/loading' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get '/installation/loading'
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    context 'when it is an authenticated user' do
      let!(:user) { create(:user) }
      let!(:installation) { create(:installation, status: 'in_progress') }

      before do
        sign_in user
      end

      it 'should get loading installation url' do
        allow(Installation).to receive(:first).and_return(installation)
        allow(installation).to receive(:complete_installation!).and_return(true)
        get '/installation/loading'
        expect(response).to have_http_status(200)
        expect(response.body).to include('We are creating your company...')
      end
    end
  end
end
