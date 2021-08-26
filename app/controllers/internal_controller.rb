class InternalController < ApplicationController
  before_action :authenticate_user!
  layout "internal"

end
