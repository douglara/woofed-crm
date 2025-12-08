# frozen_string_literal: true

class Apps::Chatwoot::ApiClient
  include Apps::Chatwoot::ApiClient::UserProfile

  def initialize(chatwoot)
    @chatwoot = chatwoot
    @request_headers = chatwoot.request_headers
    @connection = create_connection
  end

  def create_connection
    retry_options = {
      max: 5,
      interval: 0.05,
      interval_randomness: 0.5,
      backoff_factor: 2,
      exceptions: [
        Faraday::ConnectionFailed,
        Faraday::TimeoutError,
        'Timeout::Error'
      ]
    }

    Faraday.new(@chatwoot.chatwoot_endpoint_url) do |faraday|
      faraday.options.open_timeout = 5
      faraday.options.timeout = 10
      faraday.headers = { 'api_access_token': @chatwoot.chatwoot_user_token.to_s, 'Content-Type': 'application/json' }
      faraday.request :retry, retry_options
    end
  end

  def get_request(path, params = {})
    response = @connection.get(path, params)

    if response.success?
      { ok: JSON.parse(response.body), request: response }
    else
      logger_error('Failed get_request', response)
      { error: response.body, request: response }
    end
  end

  def logger_error(message, request)
    Rails.logger.error "Chatwoot Api Client error #{message} - Chatwoot #{@chatwoot.id}"
    Rails.logger.error "Chatwoot: #{@chatwoot.inspect}"
    Rails.logger.error "Request: #{request.inspect}"
  end
end
