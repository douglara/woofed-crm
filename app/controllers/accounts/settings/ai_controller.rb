# frozen_string_literal: true

class Accounts::Settings::AiController < InternalController
  before_action :set_account

  def edit; end

  def update
    if @account.update(account_params)
      redirect_to edit_account_ai_path(current_user.account, current_user.account),
                  notice: t('flash_messages.updated', model: Account.model_name.human)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_account
    @account = current_user.account
  end

  def account_params
    params.require(:account).permit(:woofbot_auto_reply)
  end
end
