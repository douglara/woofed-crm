class ApplicationController < ActionController::Base
  include Pagy::Backend
  if ENV['HIGHLIGHT_PROJECT_ID'].present?
    require 'highlight'
    include Highlight::Integrations::Rails
    around_action :with_highlight_context
  end
  before_action :set_account
  before_action :account_setup

  def account_setup
    redirect_to new_account_path if @account.blank? && controller_name != 'account'
  end

  private

  def set_account
    @account = Current.account
  end
end
