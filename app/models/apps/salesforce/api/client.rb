# frozen_string_literal: true

# Every call to a Salesforce org goes through here. Endpoints live in one class
# each under Apps::Salesforce::Api and delegate to this one, so none of them
# repeats the bearer token, the refresh-and-retry on a 401, the guard for
# credentials that can no longer be decrypted, or the error normalisation.
class Apps::Salesforce::Api::Client
  RETRY_OPTIONS = {
    max: 3,
    interval: 0.05,
    interval_randomness: 0.5,
    backoff_factor: 2,
    exceptions: [Faraday::ConnectionFailed, Faraday::TimeoutError, 'Timeout::Error']
  }.freeze

  def initialize(salesforce)
    @salesforce = salesforce
  end

  def get(path, params = {})
    call { |connection| connection.get(path, params) }
  end

  # Bulk results come back as CSV, so the body is handed over untouched.
  def get_raw(path, params = {})
    call(parse: false) { |connection| connection.get(path, params) }
  end

  def post(path, body)
    call { |connection| connection.post(path, body.to_json) }
  end

  private

  attr_reader :salesforce

  def call(parse: true, retried: false, &block)
    return unreadable_credentials unless credentials_readable?

    response = block.call(connection)

    return { ok: parse ? parse_body(response.body) : response.body, request: response } if response.success?
    return retry_with_fresh_token(parse: parse, &block) if response.status == 401 && !retried

    logger_error(response)
    { error: error_message(response), request: response }
  rescue Faraday::Error => e
    Rails.logger.error("Apps::Salesforce::Api::Client failed: #{e.class} - Salesforce #{salesforce.id}")
    { error: I18n.t('apps.salesforce.oauth_errors.connection_failed') }
  end

  # A 401 means the session died earlier than token_expires_at predicted, which is
  # expected: Salesforce never tells us the real session length.
  def retry_with_fresh_token(parse:, &block)
    refresh = Apps::Salesforce::Connection::RefreshToken.new(salesforce, force: true).call
    return { error: refresh[:error] } if refresh.key?(:error)

    @connection = nil
    call(parse: parse, retried: true, &block)
  end

  # A rotated SECRET_KEY_BASE leaves the stored credentials undecryptable. It is
  # the same dead end as an app the customer revoked, so it lands in the same
  # state: reconnect.
  def credentials_readable?
    salesforce.access_token
    salesforce.refresh_token
    true
  rescue ActiveRecord::Encryption::Errors::Decryption
    false
  end

  def unreadable_credentials
    Rails.logger.error("Salesforce credentials could not be decrypted - Salesforce #{salesforce.id}")
    salesforce.error!

    { error: I18n.t('apps.salesforce.oauth_errors.unreadable_credentials') }
  end

  def connection
    @connection ||= Faraday.new(salesforce.instance_url) do |faraday|
      faraday.options.open_timeout = 5
      faraday.options.timeout = 30
      faraday.headers = {
        'Authorization': "Bearer #{salesforce.access_token}",
        'Content-Type': 'application/json'
      }
      faraday.request :retry, RETRY_OPTIONS
    end
  end

  def parse_body(body)
    JSON.parse(body.to_s)
  rescue JSON::ParserError
    {}
  end

  # Salesforce answers errors with a list of { message, errorCode }.
  def error_message(response)
    body = parse_body(response.body)
    messages = body.is_a?(Array) ? body.filter_map { |error| error['message'] } : []

    messages.presence&.join(', ') || "HTTP #{response.status}"
  end

  # Record ids and counts only: Salesforce payloads are PII.
  def logger_error(response)
    Rails.logger.error("Apps::Salesforce::Api::Client error #{response.status} - Salesforce #{salesforce.id}")
  end
end
