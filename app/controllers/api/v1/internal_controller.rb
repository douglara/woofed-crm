class Api::V1::InternalController < ActionController::API
  include Pagy::Backend
  include Api::Concerns::RequestExceptionHandler
  before_action :authenticate_user
  around_action :handle_with_exception, unless: :devise_controller?

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
