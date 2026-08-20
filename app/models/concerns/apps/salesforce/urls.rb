module Apps::Salesforce::Urls
  extend ActiveSupport::Concern

  # Static, global Salesforce hosts. A sandbox org only authenticates against
  # test, a production org only against login. After the token response arrives,
  # every API call uses the instance_url it returned instead.
  LOGIN_URLS = {
    'production' => 'https://login.salesforce.com',
    'sandbox' => 'https://test.salesforce.com'
  }.freeze

  def login_url
    LOGIN_URLS.fetch(environment)
  end

  # Salesforce accepts token calls on the instance once it is known, and requires
  # the login host before that.
  def token_url
    "#{instance_url.presence || login_url}/services/oauth2/token"
  end

  def revoke_url
    "#{instance_url.presence || login_url}/services/oauth2/revoke"
  end

  def api_url
    "#{instance_url}/services/data/#{api_version}"
  end

  def bulk_query_url
    "#{api_url}/jobs/query"
  end

  # Fixed for the whole install: it is registered by hand in the customer's
  # External Client App, so it can never carry an account or connection id.
  def redirect_uri
    Rails.application.routes.url_helpers.apps_salesforces_oauth_callback_url
  end
end
