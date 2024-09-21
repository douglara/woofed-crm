class InstallationController < ApplicationController
  before_action :authenticate_user!, except: %i[new create]
  layout 'installations_loading', only: %i[loading]
  layout 'devise'

  def new
  end

  def step_1
  end

  def step_2
  end

  def step_3
  end

  def loading
  end

  def create
    installation = Installation.new(installation_params)
    user = User.new(user_params.merge(password: SecureRandom.hex(8)))
    result = ActiveRecord::Base.transaction do
      installation.save!
      user.save!
    end

    if result
      sign_in(user)
      redirect_to installation_step_1_path
    else
      render :new
    end
  end

  def installation_params
    params.require(:installation).permit(:id, :key1, :key2, :token)
  end

  def user_params
    params.require(:user).permit(:email, :full_name)
  end
end
