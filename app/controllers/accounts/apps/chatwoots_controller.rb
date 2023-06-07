class Accounts::Apps::ChatwootsController < InternalController
  before_action :set_chatwoot, only: %i[ edit disable new_connection pair_qr_code new_connection_status ]

  def new
    current_user.account.apps_chatwoots.create(
      account: current_user.account
    ) if current_user.account.apps_chatwoots.blank?

    redirect_to edit_account_apps_chatwoot_path(current_user.account, current_user.account.apps_chatwoots.first)
  end

  def edit
  end

  def update
  end

  private
    def set_chatwoot
      @chatwoot = current_user.account.apps_chatwoots.first
    end

    def chatwoot_params
      params.require(:apps_chatwoot).permit(:endpoint_url, :user_token)
    end
end