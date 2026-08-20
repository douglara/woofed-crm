# frozen_string_literal: true

# Mints a new access token from the stored refresh token.
#
# The work happens under a row lock because web, sidekiq and goodjob refresh
# independently: Salesforce keeps a limited number of active access tokens per
# user per app, so concurrent refreshes can evict a token another process is
# still using.
class Apps::Salesforce::Connection::RefreshToken
  def initialize(salesforce, force: false)
    @salesforce = salesforce
    @force = force
  end

  def call
    return { error: I18n.t('apps.salesforce.oauth_errors.missing_refresh_token') } if salesforce.refresh_token.blank?

    salesforce.with_lock do
      # Whoever held the lock may have refreshed already.
      next { ok: salesforce } unless force || salesforce.token_expired?

      handle(request)
    end
  end

  private

  attr_reader :salesforce, :force

  def request
    Apps::Salesforce::Oauth::TokenRequest.new(
      salesforce,
      grant_type: 'refresh_token',
      refresh_token: salesforce.refresh_token,
      client_id: salesforce.client_id,
      client_secret: salesforce.client_secret
    ).call
  end

  # A refusal from Salesforce means the connection needs the user's attention --
  # the refresh token was revoked, or the app was changed. An unreachable org
  # carries no code and is left alone, since it is usually transient.
  def handle(result)
    salesforce.error! if result[:code].present?

    result
  end
end
