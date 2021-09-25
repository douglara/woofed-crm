class Api::V1::InternalController < ActionController::API
  before_action :authenticate_user

  def authenticate_user
    header = request.headers['Authorization']
    header = header.split(' ').last if header

    begin
      decoded = Users::JsonWebToken.decode_user(header)
      @current_user = decoded[:ok]
    rescue ActiveRecord::RecordNotFound => e
      render json: { errors: e.message }, status: :unauthorized
    rescue JWT::DecodeError => e
      render json: { errors: e.message }, status: :unauthorized
    end
  end
end
