class Webhook::ApiClient
  def initialize(webhook)
    @webhook = webhook
    @connection = create_connection
  end

  def create_connection
    Faraday.new(@webhook.url) do |faraday|
      faraday.options.timeout = 5
      faraday.headers = { 'Content-Type': 'application/json' }
    end
  end

  def post_request
    response = @connection.post

    if response.success?
      { ok: response.status, request: response }
    else
      logger_error('Failed to validate webhook URL', response)
      { error: "Invalid or unreachable URL (status: #{response.status})", request: response }
    end
  end

  private

  def logger_error(message, response)
    Rails.logger.error "Webhook Api Client error: #{message} - Webhook #{@webhook.id || 'new'}"
    Rails.logger.error "Webhook: #{@webhook.inspect}"
    Rails.logger.error "Request: #{response.inspect}"
  end
end
