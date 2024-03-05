class ApplicationController < ActionController::Base

  include Pagy::Backend
  if ENV['HIGHLIGHT_PROJECT_ID'].present?
    require "highlight"
    include Highlight::Integrations::Rails
    around_action :with_highlight_context
  end
end
