class Accounts::Apps::ChatwootsController < InternalController
  before_action :set_chatwoot, only: %i[edit update destroy]

  def new
    if current_user.account.apps_chatwoots.blank?
      @chatwoot = current_user.account.apps_chatwoots.new
    else
      redirect_to edit_account_apps_chatwoot_path(current_user.account, current_user.account.apps_chatwoots.first)
    end
  end

  def edit; end

  def create
    result = Accounts::Apps::Chatwoots::Create.call(current_user.account, chatwoot_params)
    @chatwoot = result[result.keys.first]
    if result.key?(:ok)
      redirect_to edit_account_apps_chatwoot_path(current_user.account, @chatwoot),
                  notice: t('flash_messages.created', model: Apps::Chatwoot.model_name.human)
    else
      render :new
    end
  end

  def destroy
    result = Accounts::Apps::Chatwoots::Delete.call(current_user.account, @chatwoot)
    if result.key?(:ok)
      redirect_to account_settings_path(current_user.account),
                  notice: t('flash_messages.deleted', model: Apps::Chatwoot.model_name.human)
    end
  end

  def update
    @chatwoot.update(chatwoot_params)
    redirect_to edit_account_apps_chatwoot_path(current_user.account, current_user.account.apps_chatwoots.first)
  end

  private

  def set_chatwoot
    @chatwoot = current_user.account.apps_chatwoots.first
  end

  def chatwoot_params
    params.require(:apps_chatwoot).permit(:chatwoot_endpoint_url, :chatwoot_account_id, :chatwoot_user_token, :active)
  end
end
