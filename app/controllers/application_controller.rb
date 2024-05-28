class ApplicationController < ActionController::Base
  include Localized
  include Pagy::Backend

  if ENV['HIGHLIGHT_PROJECT_ID'].present?
    require 'highlight'
    include Highlight::Integrations::Rails
    around_action :with_highlight_context
  end
end
