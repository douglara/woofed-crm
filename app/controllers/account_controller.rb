class AccountController < ApplicationController
  def new
    @account = Account.new
  end

  def create
    @account = Account.new(account_params)

    if @account.save
      redirect_to new_user_registration_path, notice: "Account created successfully. Please sign in."
    else
      render :new
    end
  end

  private

  def account_params
    params.require(:account).permit(:name)
  end
end
