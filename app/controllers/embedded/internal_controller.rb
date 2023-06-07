class Embedded::InternalController < ApplicationController
  before_action :authenticate_app

  def authenticate_app
    token = params['token']

    begin
      @chatwoot = Apps::Chatwoot.find_by_embedding_token(token)
      @current_account = @chatwoot.account
      @current_user = @current_account.users.first
    rescue ActiveRecord::RecordNotFound => e
      render json: { errors: e.message }, status: :unauthorized
    rescue JWT::DecodeError => e
      render json: { errors: e.message }, status: :unauthorized
    end
  end
end
