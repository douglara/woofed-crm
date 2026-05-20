module Mcp::Concerns::RequestExceptionHandler
  extend ActiveSupport::Concern

  def handle_with_exception
    yield
  rescue ActiveRecord::RecordNotFound => e
    log_handled_error(e)
    not_found_error('Resource could not be found')
  rescue ActiveRecord::RecordInvalid => e
    log_handled_error(e)
    record_invalid_error(e)
  rescue ActionController::ParameterMissing => e
    log_handled_error(e)
    unprocessable_error(e.message)
  rescue ArgumentError => e
    log_handled_error(e)
    unprocessable_error("Invalid arguments: #{e.message}")
  ensure
    Current.reset
  end

  private

  def not_found_error(message)
    { error: message, status: 'not_found' }.to_json
  end

  def unprocessable_error(message)
    { error: message, status: 'unprocessable_entity' }.to_json
  end

  def record_invalid_error(exception)
    {
      error: exception.record.errors.full_messages,
      attributes: exception.record.errors.attribute_names,
      status: 'unprocessable_entity'
    }.to_json
  end

  def log_handled_error(exception)
    Rails.logger.info("[MCP] Handled error: #{exception.inspect}")
  end
end
