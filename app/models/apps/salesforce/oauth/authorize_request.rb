# frozen_string_literal: true

# Builds the URL the user is sent to in order to consent, using PKCE. The verifier
# is returned so the caller can keep it in the session until the callback comes
# back -- it never leaves this install.
class Apps::Salesforce::Oauth::AuthorizeRequest
  # `api` covers REST, Bulk and Pub/Sub; `refresh_token offline_access` is what
  # makes the connection survive the session.
  SCOPES = 'api refresh_token offline_access'

  def initialize(salesforce)
    @salesforce = salesforce
    @state = SecureRandom.urlsafe_base64(24)
    @code_verifier = SecureRandom.urlsafe_base64(64)
  end

  def call
    { url: authorize_url, state: state, code_verifier: code_verifier }
  end

  private

  attr_reader :salesforce, :state, :code_verifier

  def authorize_url
    "#{salesforce.login_url}/services/oauth2/authorize?#{query}"
  end

  def query
    {
      response_type: 'code',
      client_id: salesforce.client_id,
      redirect_uri: salesforce.redirect_uri,
      scope: SCOPES,
      state: state,
      code_challenge: code_challenge,
      code_challenge_method: 'S256'
    }.to_query
  end

  def code_challenge
    Base64.urlsafe_encode64(Digest::SHA256.digest(code_verifier), padding: false)
  end
end
