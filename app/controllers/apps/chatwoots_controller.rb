class Apps::ChatwootsController < ActionController::Base
  before_action :load_chatwoot, execpt: :webhooks
  before_action :authenticate_by_token, if: -> { current_user.blank? }
  skip_before_action :verify_authenticity_token, execpt: :embedding
  layout "embed"

  def webhooks
    Accounts::Apps::Chatwoots::Webhooks::ProcessWebhookJob.perform_later(params.to_json, params['token'])
    render json: { ok: true }, status: 200
  end

  def embedding
  end

  def embedding_init_authenticate
    @token = params['token']
  end

  def embedding_authenticate
    event = JSON.parse(params['event'])
    @user_email = event['data']['currentAgent']['email']
    user = User.find_by(email: @user_email, account_id: @chatwoot.account_id)
    if user.blank?
      return render 'user_not_found', status: 400
    end
    sign_in(user)
    redirect_to embedding_apps_chatwoots_path()
  end
  private

  def authenticate_by_token
    if @chatwoot.present? && action_name == 'embedding'
      redirect_to embedding_init_authenticate_apps_chatwoots_path(token: params['token']) if action_name != 'embedding_authenticate'
    else
      render plain: "Unauthorized", status: 400  if @chatwoot.blank?
    end
  end

  def load_chatwoot
    @chatwoot = Apps::Chatwoot.find_by(embedding_token: params['token'])
  end
end
