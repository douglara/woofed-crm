class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?
  layout :layout_by_resource
  include Pagy::Backend

  
  if ENV['HIGHLIGHT_PROJECT_ID'].present?
    require "highlight"
    include Highlight::Integrations::Rails
    around_action :with_highlight_context
  end
  
  protected
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:full_name, :email, :password, :password_confirmation, account_attributes: [:name]])
  end
  private
  
  def layout_by_resource
    if devise_controller?
      "devise"
    else
      "application"
    end
  end
end
