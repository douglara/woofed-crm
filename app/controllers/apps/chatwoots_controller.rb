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
    @embed_user = embed_user
  end

  def embedding_init_authenticate
    @token = params['token']
  end

  def embedding_authenticate
    event = JSON.parse(params['event'])
    @user_email = event['data']['currentAgent']['email']
    user = User.find_by(email: @user_email)
    return render 'user_not_found', status: 400 if user.blank?

    redirect_to embedding_apps_chatwoots_path(token: params['token'], ut: generate_embed_token(user))
  end

  private

  def check_user_authentication
    embed_user.blank?
  end

  def embed_user
    @embed_user ||= begin
      user = current_user || user_from_embed_token
      sign_in(user, store: false) if user.present? && current_user.blank?
      user
    end
  end

  def generate_embed_token(user)
    Rails.application.message_verifier('chatwoot_embed').generate(user.id, expires_in: 1.hour)
  end

  def user_from_embed_token
    return nil unless params[:ut].present?

    user_id = Rails.application.message_verifier('chatwoot_embed').verify(params[:ut])
    User.find_by_id(user_id)
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    nil
  end

  def authenticate_by_token
    if @chatwoot.present? && action_name == 'embedding'
      redirect_to embedding_init_authenticate_apps_chatwoots_path(token: params['token'])
    elsif @chatwoot.blank?
      render plain: 'Unauthorized', status: 400
    end
  end

  def load_chatwoot
    @chatwoot = Apps::Chatwoot.find_by(embedding_token: params['token'])
  end
end
