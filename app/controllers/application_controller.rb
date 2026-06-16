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
  before_action :track_embedded_context
  helper_method :embedded?

  # True when the page is being rendered inside the Chatwoot embedded widget.
  # The flag tracks how the page is actually loaded (see track_embedded_context),
  # so it never sticks to a direct browser visit. `params[:embed]` is honoured as
  # a stateless fallback.
  def embedded?
    session[:embedded].present? || params[:embed].present?
  end

  private

  # Keep the embedded (chrome-less) state in sync with the real rendering
  # context, so it never bleeds from the Chatwoot iframe into a direct visit.
  # Browsers send Sec-Fetch-Dest=iframe when the document loads inside the
  # iframe and =document on a top-level navigation. Turbo/Inertia fetches send
  # =empty and leave the flag untouched, preserving it across in-app navigation.
  def track_embedded_context
    case request.headers['Sec-Fetch-Dest']
    when 'iframe'
      session[:embedded] = true
    when 'document'
      session.delete(:embedded)
    end
  end

  def setup_installation
    if Installation.installation_flow? && !request.path.include?('/installation')
      redirect_to installation_new_path and return
    end
  end

  def set_account
    @account = Current.account
  end
end
