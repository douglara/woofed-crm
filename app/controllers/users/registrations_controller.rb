# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_permitted_parameters

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up,
                                      keys: [:full_name, :email, :phone, :password, :password_confirmation,
                                             { account_attributes: %i[name site_url] }])
  end
end
