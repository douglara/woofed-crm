# frozen_string_literal: true

# Salesforce answers a failed token call with a short machine code and an opaque
# description. The codes worth translating are the ones whose fix differs: a
# mistyped callback URL is edited in the External Client App, while a bad consumer
# secret is re-pasted into Woofed.
class Apps::Salesforce::Oauth::ErrorMessage
  KNOWN_CODES = %w[
    redirect_uri_mismatch
    invalid_client
    invalid_client_id
    invalid_grant
    access_denied
    inactive_user
  ].freeze

  def self.call(code, redirect_uri: nil)
    key = KNOWN_CODES.include?(code.to_s) ? code : 'unknown'

    I18n.t("apps.salesforce.oauth_errors.#{key}", redirect_uri: redirect_uri)
  end
end
