require 'rails_helper'

RSpec.describe InstallationController, type: :request do
  let(:first_user) { User.first }
  let(:first_installation) { Installation.first }
  let(:first_account) { Account.first }
  describe 'GET /installation/create' do
    context 'when it is an unauthenticated user' do
      context 'when there are valid params' do
        it 'should create user and installation and redirect to step_1 path' do
          get '/installation/create',
              params: { user: { email: 'yukioteste@email.com', full_name: 'Yukio teste' },
                        installation: { id: 1, key1: 'key1teste', key2: 'key2teste', token: 'tokenteste' } }
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
            get '/installation/create',
                params: { user: { email: '', full_name: 'Yukio teste', phone: '@dsad55' },
                          installation: { id: 1, key1: 'key1teste', key2: 'key2teste', token: 'tokenteste' } }
            expect(response).to have_http_status(:unprocessable_entity)
            expect(User.count).to eq(0)
            expect(Installation.count).to eq(0)
          end
          context 'when there is no user params' do
            it 'should not create user and installation and render new action installation controller' do
              expect do
                get '/installation/create',
                    params: {
                      installation: { id: 1, key1: 'key1teste', key2: 'key2teste', token: 'tokenteste' }
                    }
              end.to raise_error(ActionController::ParameterMissing, /user/)
              expect(User.count).to eq(0)
              expect(Installation.count).to eq(0)
            end
          end
        end
        context 'when installation params is invalid' do
          context 'when installation params is blank' do
            it 'should not create user and installation and render new action installation controller' do
              get '/installation/create',
                  params: { user: { email: 'yukio@email.com', full_name: 'Yukio teste' },
                            installation: { id: '', key1: '', key2: '', token: '' } }
              expect(response).to have_http_status(:unprocessable_entity)
              expect(User.count).to eq(0)
              expect(Installation.count).to eq(0)
            end
          end

          context 'when there is no installation params' do
            it 'should not create installation and installation and render new action installation controller' do
              expect do
                get '/installation/create',
                    params: {
                      user: { email: 'yukio@email.com', full_name: 'Yukio teste' }
                    }
              end.to raise_error(ActionController::ParameterMissing, /installation/)
              expect(User.count).to eq(0)
              expect(Installation.count).to eq(0)
            end
          end
        end
      end

      context 'when account and user already exists' do
        let!(:account) { create(:account) }
        let!(:user) { create(:user, account:) }
        it 'should update user and create a new installation and redirect to step_1' do
          get '/installation/create',
              params: { user: { email: user.email, full_name: 'Yukio teste' },
                        installation: { id: 1, key1: 'key1teste', key2: 'key2teste', token: 'tokenteste' } }
          expect(response).to have_http_status(302)
          expect(response).to redirect_to(installation_step_1_path)
          expect(User.count).to eq(1)
          expect(user.reload.valid_password?('Password1!')).to be_falsey
          expect(Installation.count).to eq(1)
        end
      end
      context 'when there is an installation' do
        context 'when installation status is completed' do
          let!(:installation) { create(:installation, status: 'completed') }

          it 'should not create user and installation and raise route error' do
            first_installation.complete_installation
            expect do
              get '/installation/create',
                  params: { user: { email: 'yukio@email.com', full_name: 'Yukio teste' },
                            installation: { id: 1, key1: 'key1teste', key2: 'key2teste', token: 'tokenteste' } }
            end.to raise_error(ActionController::RoutingError)

            expect(User.count).to eq(0)
            expect(Installation.count).to eq(1)
          end
        end
        context 'when installation status is in_progress' do
          let!(:installation) { create(:installation, status: 'in_progress') }
          it 'should create user and installation and redirect to step_1 path' do
            load "#{Rails.root}/app/controllers/application_controller.rb"
            Rails.application.reload_routes!
            get '/installation/create',
                params: { user: { email: 'yukioteste@email.com', full_name: 'Yukio teste' },
                          installation: { id: '1', key1: 'key1teste', key2: 'key2teste', token: 'tokenteste' } }
            expect(response).to redirect_to(installation_step_1_path)
            expect(first_user.full_name).to eq('Yukio teste')
            expect(first_user.email).to eq('yukioteste@email.com')
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
          get '/installation/create',
              params: { user: { email: 'yukio@email.com', full_name: 'Yukio teste' },
                        installation: { id: 1, key1: 'key1teste', key2: 'key2teste', token: 'tokenteste' } }
          expect(response).to redirect_to(installation_step_1_path)
          expect(User.count).to eq(2)
          expect(Installation.count).to eq(1)
        end
      end
      context 'when there is an installation' do
        context 'when installation status is completed' do
          let!(:installation) { create(:installation, status: 'completed') }
          it 'should not create user and installation and raise route error' do
            first_installation.complete_installation
            expect do
              get '/installation/create',
                  params: { user: { email: 'yukio@email.com', full_name: 'Yukio teste' },
                            installation: { id: 1, key1: 'key1teste', key2: 'key2teste', token: 'tokenteste' } }
            end.to raise_error(ActionController::RoutingError)
            expect(User.count).to eq(1)
            expect(Installation.count).to eq(1)
          end
        end
        context 'when installation status is in_progress' do
          let(:installation) { create(:installation, status: 'in_progress') }
          it 'should create user and installation and redirect to step_1' do
            load "#{Rails.root}/app/controllers/application_controller.rb"
            Rails.application.reload_routes!
            get '/installation/create',
                params: { user: { email: 'yukio@email.com', full_name: 'Yukio teste' },
                          installation: { id: 1, key1: 'key1teste', key2: 'key2teste', token: 'tokenteste' } }
            expect(response).to redirect_to(installation_step_1_path)
            expect(User.count).to eq(2)
            expect(Installation.count).to eq(1)
          end
        end
      end
    end
  end

  describe 'setup_installation' do
    context 'GET /accounts/1/users' do
      context 'when there is no user and installation registered' do
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
          context 'when installation status is in_progress' do
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
            first_installation.complete_installation
            expect do
              get '/installation/new'
            end.to raise_error(ActionController::RoutingError)
          end
        end
        context 'when installation status is in_progress' do
          let!(:installation) { create(:installation, status: 'in_progress') }
          it 'should get new installation url' do
            load "#{Rails.root}/app/controllers/application_controller.rb"
            Rails.application.reload_routes!
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
      context 'when there is installation' do
        context 'when installation status is completed' do
          let!(:installation) { create(:installation, status: 'completed') }
          it 'should raise error' do
            first_installation.complete_installation
            expect do
              get '/installation/new'
            end.to raise_error(ActionController::RoutingError)
          end
        end
        context 'when installation status is in_progress' do
          let!(:installation) { create(:installation, status: 'in_progress') }
          it 'should get new installation url' do
            load "#{Rails.root}/app/controllers/application_controller.rb"
            Rails.application.reload_routes!
            get '/installation/new'
            expect(response).to have_http_status(200)
            expect(response.body).to include('Log in with')
            expect(response.body).to include('You are one step away from your company growing.')
          end
        end
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
            first_installation.complete_installation
            expect do
              get '/installation/step_1'
            end.to raise_error(ActionController::RoutingError)
          end
        end
        context 'when installation status is in_progress' do
          let!(:installation) { create(:installation, status: 'in_progress') }
          it 'should get step_1 installation url' do
            load "#{Rails.root}/app/controllers/application_controller.rb"
            Rails.application.reload_routes!
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
        patch '/installation/update_step_1', params: { user: { full_name: 'Yukio', phone: '+552299887875' } }
        expect(response).to have_http_status(302)
        expect(response).to redirect_to(installation_step_2_path)
        expect(first_user.reload.full_name).to eq('Yukio')
        expect(first_user.reload.phone).to eq('+552299887875')
      end
      context 'when there are invalid params' do
        it 'should not update user and raise error' do
          patch '/installation/update_step_1', params: { user: { full_name: '', phone: '123456' } }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include('Phone (cell) is invalid')
        end
      end

      context 'when there is installation' do
        context 'when installation status is completed' do
          let!(:installation) { create(:installation, status: 'completed') }
          it 'should raise route error' do
            first_installation.complete_installation
            expect do
              patch '/installation/update_step_1', params: { user: { full_name: 'Yukio', phone: '+552299887875' } }
            end.to raise_error(ActionController::RoutingError)
            expect(user.reload.full_name).not_to eq('Yukio')
          end
        end
        context 'when installation status is in_progress' do
          let(:installation) { create(:installation, status: 'in_progress') }
          it 'should update user and redirect to step 2 installation path' do
            load "#{Rails.root}/app/controllers/application_controller.rb"
            Rails.application.reload_routes!
            patch '/installation/update_step_1', params: { user: { full_name: 'Yukio', phone: '+552299887875' } }
            expect(response).to have_http_status(302)
            expect(response).to redirect_to(installation_step_2_path)
            expect(first_user.reload.full_name).to eq('Yukio')
            expect(first_user.reload.phone).to eq('+552299887875')
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
        patch '/installation/update_step_2', params: { user: { password: '123456', password_confirmation: '123456' } }
        expect(response).to have_http_status(302)
        expect(response).to redirect_to(installation_step_3_path)
      end
      context 'when there are invalid params' do
        it 'should not update user and raise error' do
          patch '/installation/update_step_2',
                params: { user: { password: '123456', password_confirmation: '123456789' } }
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
      let!(:account) { create(:account) }
      let!(:user) { create(:user, account:) }

      before do
        sign_in user
      end

      it 'should get step_3 installation url' do
        get '/installation/step_3'
        expect(response).to have_http_status(200)
        expect(response.body).to include('Company Info')
        expect(response.body).to include('Site URL')
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
      let!(:account) { create(:account) }
      let!(:user) { create(:user, account:) }

      before do
        sign_in user
      end

      it 'should update account and redirect to loading installation path' do
        patch '/installation/update_step_3',
              params: { account: { name: 'Woofed company', site_url: 'app.woofedcrm.com' } }
        expect(response).to have_http_status(302)
        expect(response).to redirect_to(installation_loading_path)
        expect(first_account.name).to eq('Woofed company')
        expect(first_account.site_url).to eq('https://app.woofedcrm.com')
      end
      context 'when there are invalid params' do
        it 'should not update user and raise error' do
          patch '/installation/update_step_3',
                params: { account: { name: '', site_url: '' } }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to match(/Name can&#39;t be blank/)
        end
      end
    end
  end
  skip 'GET installation/loading' do
  end
end
