class Apps::ChatwootsController < ActionController::API
  before_action :authenticate_token

  def webhooks
    render json: { ok: true }, status: 200
  end

  def embedding
    @token = params['token']
  end

  def embedding_auth
    puts params
  end

  def authenticate_token
    puts(params)
    token = params['token']

    @chatwoot = Apps::Chatwoot.find_by(embedding_token: token)
    render plain: "Unauthorized", status: 400  if @chatwoot.blank?
  end
end