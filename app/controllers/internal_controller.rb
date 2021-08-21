class InternalController < ApplicationController
  before_action :authenticate_user!
end
