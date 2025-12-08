class Accounts::Settings::AccountsController < InternalController
  include AccountConcern

  def edit; end

  def update
    if @account.update(account_params)
      respond_to do |format|
        format.html do
          redirect_to edit_account_settings_account_path(@account),
                      notice: t('flash_messages.updated', model: Account.model_name.human)
        end
        format.turbo_stream
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def account_params
    params.require(:account).permit(*permitted_account_params)
  end
end
