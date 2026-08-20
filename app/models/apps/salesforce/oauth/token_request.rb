# frozen_string_literal: true

# The single place that talks to /services/oauth2/token. Both the authorization
# code exchange and the refresh use the same request shape and the same response
# handling, and differ only in the form parameters they send.
#
# A failure carries `code` when Salesforce itself rejected the call, and omits it
# when the org could not be reached -- the caller uses that to tell a revoked
# connection apart from a transient network error.
class Apps::Salesforce::Oauth::TokenRequest
  def initialize(salesforce, form_params)
    @salesforce = salesforce
    @form_params = form_params
  end

  def call
    response = post
    body = parse(response.body)

    unless response.success?
      Rails.logger.error("Salesforce token request refused: #{body['error']}")
      return { error: error_message(body['error']), code: body['error'] }
    end

    salesforce.apply_token_response!(body)
    { ok: salesforce }
  rescue Faraday::Error => e
    Rails.logger.error("Salesforce token request failed: #{e.class}")
    { error: I18n.t('apps.salesforce.oauth_errors.connection_failed') }
  end

  private

  attr_reader :salesforce, :form_params

  def post
    Faraday.post(salesforce.token_url) do |request|
      request.headers['Content-Type'] = 'application/x-www-form-urlencoded'
      request.body = URI.encode_www_form(form_params)
    end
  end

  def parse(body)
    JSON.parse(body.to_s)
  rescue JSON::ParserError
    {}
  end

  def error_message(code)
    Apps::Salesforce::Oauth::ErrorMessage.call(code, redirect_uri: salesforce.redirect_uri)
  end
end
