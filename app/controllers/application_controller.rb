class ApplicationController < ActionController::Base
  include Localized
  include Pagy::Backend

  if ENV['HIGHLIGHT_PROJECT_ID'].present?
    require 'highlight'
    include Highlight::Integrations::Rails
    around_action :with_highlight_context
  end
  before_action :set_account
  before_action :setup_installation if Installation.installation_flow?

  private

  def setup_installation
    installation_routes_regex = %r{\A/installation/(new|create|step_1|step_2|step_3|update_step_1|update_step_2|update_step_3|loading)\z}
    return unless Installation.installation_flow? && request.path !~ installation_routes_regex

    redirect_to installation_new_path and return
  end

  def set_account
    @account = Current.account
  end
end
