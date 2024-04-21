class InternalController < ApplicationController
  before_action :sign_in_preview_env
  before_action :authenticate_user!
  layout "internal"

  def sign_in_preview_env
    sign_in User.first if ENV['PREVIEW_APP'].present? && current_user.blank?
  end
end
