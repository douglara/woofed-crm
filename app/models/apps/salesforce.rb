# == Schema Information
#
# Table name: apps_salesforces
#
#  id               :bigint           not null, primary key
#  access_token     :text
#  api_version      :string           default("v64.0"), not null
#  client_secret    :text
#  environment      :string           default("production"), not null
#  instance_url     :string           default(""), not null
#  name             :string           default(""), not null
#  refresh_token    :text
#  settings         :jsonb            not null
#  status           :string           default("inactive"), not null
#  token_expires_at :datetime
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  client_id        :string           default(""), not null
#  organization_id  :string           default(""), not null
#
class Apps::Salesforce < ApplicationRecord
  LOGIN_URLS = {
    'production' => 'https://login.salesforce.com',
    'sandbox' => 'https://test.salesforce.com'
  }.freeze

  # Salesforce does not return `expires_in` on the token response, so
  # token_expires_at is an estimate and never the only expiry signal: the API
  # client also refreshes reactively on 401 INVALID_SESSION_ID.
  TOKEN_EXPIRY_MARGIN = 5.minutes

  encrypts :client_secret
  encrypts :access_token
  encrypts :refresh_token

  enum status: {
    'inactive': 'inactive',
    'active': 'active',
    'syncing': 'syncing',
    'error': 'error'
  }

  enum environment: {
    'production': 'production',
    'sandbox': 'sandbox'
  }

  validates :client_id, presence: true
  validates :client_secret, presence: true
  validate :only_one_connection, on: :create

  before_destroy :revoke_refresh_token

  def login_url
    LOGIN_URLS.fetch(environment)
  end

  def api_url
    "#{instance_url}/services/data/#{api_version}"
  end

  def connected?
    instance_url.present? && refresh_token.present?
  end

  def token_expired?(margin: TOKEN_EXPIRY_MARGIN)
    return false if token_expires_at.blank?

    token_expires_at <= Time.current + margin
  end

  private

  # A Woofed install talks to a single Salesforce org. The rule lives here and not
  # in the schema so that supporting several connections later is a UI change plus
  # removing this validation, with no migration.
  def only_one_connection
    return unless self.class.exists?

    errors.add(:base, I18n.t('activerecord.errors.messages.salesforce_connection_already_exists'))
  end

  # Best effort: a token Salesforce already revoked, or an unreachable org, must
  # not stop the user from disconnecting.
  def revoke_refresh_token
    return true if refresh_token.blank?

    Faraday.post("#{instance_url.presence || login_url}/services/oauth2/revoke") do |request|
      request.headers['Content-Type'] = 'application/x-www-form-urlencoded'
      request.body = URI.encode_www_form(token: refresh_token)
    end

    true
  rescue StandardError => e
    Rails.logger.error("Salesforce token revocation failed: #{e.class}")
    true
  end
end
