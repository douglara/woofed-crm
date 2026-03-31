class InternalController < ApplicationController
  before_action :sign_in_preview_env
  before_action :authenticate_user_jwt_or_cookie!
  skip_before_action :verify_authenticity_token, if: :jwt_authenticated?
  layout "internal"

  private

  def sign_in_preview_env
    sign_in User.first if ENV['PREVIEW_APP'].present? && current_user.blank?
  end

  def authenticate_user_jwt_or_cookie!
    return if current_user.present?

    result = decode_embed_jwt_from_request
    if result&.dig(:ok)
      sign_in(result[:ok], store: false)
    else
      authenticate_user!
    end
  end

  def jwt_authenticated?
    @jwt_authenticated ||= decode_embed_jwt_from_request&.dig(:ok).present?
  end

  def decode_embed_jwt_from_request
    token = bearer_token_from_header
    token ||= params[:embed_jwt].presence
    return nil unless token

    Users::JsonWebToken.decode_embed(token)
  end

  def bearer_token_from_header
    token, = ActionController::HttpAuthentication::Token.token_and_options(request)
    token
  end
end
