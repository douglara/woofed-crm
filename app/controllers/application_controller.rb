class ApplicationController < ActionController::Base
  before_action :toggle_sidebar_expanded

  include Pagy::Backend
  if ENV['HIGHLIGHT_PROJECT_ID'].present?
    require 'highlight'
    include Highlight::Integrations::Rails
    around_action :with_highlight_context
  end

  def toggle_sidebar_expanded
    if params[:sidebar_expanded]
      cookies[:sidebar_expanded] = params[:sidebar_expanded]
      head :ok
    end
  end
end
