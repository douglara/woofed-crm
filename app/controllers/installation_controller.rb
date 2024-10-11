class InstallationController < ApplicationController
  before_action :authenticate_user!, except: %i[new create]
  before_action :set_user, except: %i[new create]
  before_action :set_account, only: %i[step_3 update_step_3]

  layout 'devise'

  def new
  end

  def step_1
  end

  def update_step_1
    if @user.update(user_params)
      redirect_to installation_step_2_path
    else
      render :step_1, status: :unprocessable_entity
    end
  end

  def step_2
  end

  def update_step_2
    if @user.update(user_params)
      bypass_sign_in(@user)
      redirect_to installation_step_3_path
    else
      render :step_2, status: :unprocessable_entity
    end
  end

  def step_3
  end

  def update_step_3
    if @account.update(account_params)
      redirect_to installation_loading_path
    else
      render :step_3, status: :unprocessable_entity
    end
  end

  def loading
    Installation.first.complete_installation!
  end

  def create
    installation = Installation.first_or_initialize
    user = User.find_or_initialize_by(user_params.slice('email'))
    installation.assign_attributes(installation_params)
    user.assign_attributes(user_params)
    user.password = SecureRandom.hex(8)
    installation.user = user
    ActiveRecord::Base.transaction do
      installation.save!
      user.save!
    end
    sign_in(user)
    redirect_to installation_step_1_path
  rescue ActiveRecord::RecordInvalid, ActionController::ParameterMissing
    render :new, status: :unprocessable_entity
  end

  private

  def set_user
    @user = current_user
  end

  def set_account
    @account = Account.first_or_initialize
  end

  def installation_params
    params.require(:installation).permit(:id, :key1, :key2, :token)
  end

  def user_params
    params.require(:user).permit(:email, :full_name, :phone, :password, :password_confirmation, :avatar_url,
                                 :job_description)
  end

  def account_params
    params.require(:account).permit(:site_url, :name, :segment, :number_of_employees)
  end
end
