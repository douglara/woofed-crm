class Apps::ChatwootsController < ActionController::Base
  before_action :load_chatwoot
  before_action :authenticate_by_token, if: :check_user_authentication
  skip_before_action :verify_authenticity_token, except: :embedding
  layout 'embed'

  def webhooks
    return render json: { error: 'Chatwoot is inactive' }, status: :unprocessable_entity if @chatwoot.inactive?

    Accounts::Apps::Chatwoots::Webhooks::ProcessWebhookJob.perform_later(params.to_json, @chatwoot.account_id)
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
    return render 'user_not_found', status: 400 if user.blank?

    sign_out_all_scopes
    sign_in(user)
    redirect_to embedding_apps_chatwoots_path(token: params['token'])
  end

  private

  def check_user_authentication
    User.find_by_id(current_user&.id).blank?
  end

  def authenticate_by_token
    if @chatwoot.present? && action_name == 'embedding'
      if action_name != 'embedding_authenticate'
        redirect_to embedding_init_authenticate_apps_chatwoots_path(token: params['token'])
      end
    elsif @chatwoot.blank?
      render plain: 'Unauthorized', status: 400
    end
  end

  def load_chatwoot
    @chatwoot = Apps::Chatwoot.find_by(embedding_token: params['token'])
  end
end
