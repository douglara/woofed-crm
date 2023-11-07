class ApplicationController < ActionController::Base
  if ENV['HIGHLIGHT_PROJECT_ID'].present?
    require "highlight"
    include Highlight::Integrations::Rails
    around_action :with_highlight_context
  end

  include Pagy::Backend
end
