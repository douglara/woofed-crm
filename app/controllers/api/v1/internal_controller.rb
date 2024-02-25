class Api::V1::InternalController < ActionController::API
  include Pagy::Backend

  before_action :authenticate_user

  def authenticate_user
    header = request.headers['Authorization']
    header = header.split(' ').last if header

    begin
      decoded = Users::JsonWebToken.decode_user(header)
      @current_user = decoded[:ok]
      @current_account = @current_user.account
    rescue
      render json: { errors: 'Unauthorized' }, status: :unauthorized
    end
  end
end
