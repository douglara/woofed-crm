class Accounts::Apps::ChatwootsController < InternalController
  before_action :set_chatwoot, only: %i[ edit update destroy ]
  before_action :authenticate_token, only: %i[ embedding ]

  def new
    if current_user.account.apps_chatwoots.blank?
      @chatwoot = current_user.account.apps_chatwoots.new
    else
      redirect_to edit_account_apps_chatwoot_path(current_user.account, current_user.account.apps_chatwoots.first)
    end
  end

  def edit
  end

  def create
    @chatwoot = current_user.account.apps_chatwoots.build(chatwoot_params)
    if @chatwoot.save
      redirect_to edit_account_apps_chatwoot_path(current_user.account, @chatwoot)
    else
      render :new
    end
  end

  def destroy
    @chatwoot.destroy
    redirect_to account_settings_path(current_user.account)
  end

  def update
    @chatwoot.update(chatwoot_params)
    redirect_to edit_account_apps_chatwoot_path(current_user.account, current_user.account.apps_chatwoots.first)  
  end

  def embedding
    if params['token'].present?
      
    end
  end

  def authenticate_token
    token = params['token']

    begin
      @chatwoot = Apps::Chatwoot.find_by(embedding_token: token)
    rescue ActiveRecord::RecordNotFound => e
      render json: { errors: e.message }, status: :unauthorized
    rescue JWT::DecodeError => e
      render json: { errors: e.message }, status: :unauthorized
    end
  end

  private
    def set_chatwoot
      @chatwoot = current_user.account.apps_chatwoots.first
    end

    def chatwoot_params
      params.require(:apps_chatwoot).permit(:chatwoot_endpoint_url, :chatwoot_account_id, :chatwoot_user_token, :active)
    end
end