module Apps::Salesforce::TokenManagement
  extend ActiveSupport::Concern

  # The token response carries no `expires_in`: the session lifetime is set by the
  # customer's org (Session Settings, commonly two hours). token_expires_at is
  # therefore an estimate, and the authoritative expiry signal is a 401.
  ASSUMED_SESSION_DURATION = 2.hours
  TOKEN_EXPIRY_MARGIN = 5.minutes

  included do
    encrypts :client_secret
    encrypts :access_token
    encrypts :refresh_token

    before_destroy :revoke_refresh_token
  end

  def token_expired?(margin: TOKEN_EXPIRY_MARGIN)
    return false if token_expires_at.blank?

    token_expires_at <= Time.current + margin
  end

  # Stores what an authorization_code or a refresh_token response returns. A
  # refresh response carries no refresh_token, so the stored one is kept.
  def apply_token_response!(body)
    self.access_token = body['access_token']
    self.refresh_token = body['refresh_token'] if body['refresh_token'].present?
    self.instance_url = body['instance_url'] if body['instance_url'].present?
    self.organization_id = body['id'].to_s.split('/')[-2].to_s
    self.token_expires_at = issued_at(body) + ASSUMED_SESSION_DURATION
    self.status = 'active'
    save!
  end

  private

  # `issued_at` comes back as epoch milliseconds.
  def issued_at(body)
    return Time.current if body['issued_at'].blank?

    Time.zone.at(body['issued_at'].to_i / 1000)
  end

  # Best effort: a token Salesforce already invalidated, or an unreachable org,
  # must not stop the user from disconnecting.
  def revoke_refresh_token
    return true if refresh_token.blank?

    Faraday.post(revoke_url) do |request|
      request.headers['Content-Type'] = 'application/x-www-form-urlencoded'
      request.body = URI.encode_www_form(token: refresh_token)
    end

    true
  rescue StandardError => e
    Rails.logger.error("Salesforce token revocation failed: #{e.class}")
    true
  end
end
