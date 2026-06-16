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
    user = User.find_by(email: @user_email)
    return render 'user_not_found', status: 400 if user.blank?

    sign_out_all_scopes
    sign_in(user)
    redirect_to embedding_apps_chatwoots_path(token: params['token'])
  end

  def embedding_generate_jwt
    event = JSON.parse(params['event'])
    email = event.dig('data', 'currentAgent', 'email')
    user = User.find_by(email: email)
    return render json: { error: 'user_not_found' }, status: :not_found if user.blank?

    jwt = Users::JsonWebToken.encode_embed(user)
    render json: { jwt: }
  end

  # Serves the dashboard widget JS for this integration (config interpolated from
  # the chatwoot record). Chatwoot's DASHBOARD_SCRIPTS only needs a small loader
  # pointing here, so the widget code updates without re-injecting.
  def dashboard_script
    @frontend_url = ENV['FRONTEND_URL']
    @service_email = @chatwoot.account.users.first&.email
    render 'dashboard_script', formats: :js, layout: false, content_type: 'text/javascript'
  end

  # Signs the user in from an embed JWT and redirects to an internal path, so an
  # embedded WoofedCRM page (e.g. the pipeline) loads authenticated inside an iframe.
  def embed_login
    user = Users::JsonWebToken.decode_embed(params[:jwt])[:ok]
    return render plain: 'Unauthorized', status: :unauthorized if user.blank?

    sign_out_all_scopes
    sign_in(user)
    # Mark the session as embedded so internal pages render chrome-less inside
    # the Chatwoot iframe, across subsequent in-iframe navigation.
    session[:embedded] = true
    path = params[:path].to_s
    path = '/' unless path.start_with?('/')
    redirect_to path
  end

  private

  def check_user_authentication
    return false if action_name.in?(%w[embedding embedding_generate_jwt embed_login dashboard_script])
    User.find_by_id(current_user&.id).blank?
  end

  def authenticate_by_token
    render plain: 'Unauthorized', status: :bad_request if @chatwoot.blank?
  end

  def load_chatwoot
    @chatwoot = Apps::Chatwoot.find_by(embedding_token: params['token'])
    render plain: 'Unauthorized', status: :bad_request if @chatwoot.blank?
  end

end
