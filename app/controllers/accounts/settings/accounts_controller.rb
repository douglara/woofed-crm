class Accounts::Settings::AccountsController < InternalController
  before_action :set_account, only: %i[edit update]

  def edit; end

  def update
    if @account.update(account_params)
      redirect_to edit_account_settings_account_path(@account),
                  notice: t('flash_messages.updated', model: Account.model_name.human)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_account
    @account = Account.first
  end

  def account_params
    params.require(:account).permit(:name, :currency_code, :site_url, :segment, :number_of_employees)
  end
end
