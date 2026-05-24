# frozen_string_literal: true

# Base class for all MCP tools in this app. Subclasses are auto-discovered by
# McpController via `ApplicationTool.descendants` and registered with the
# MCP::Server instance built per-request.
#
# Subclasses must:
#   - declare `tool_name`, `description`, and (when accepting input) `input_schema`
#   - implement `def self.call(named_args..., server_context:)`
#   - return `MCP::Tool::Response.new([{ type: 'text', text: ... }])`
#
# The `server_context` hash carries `:current_user`, `:current_account`, and
# `:token` (the Doorkeeper::AccessToken) — see McpController#mcp_server.
class ApplicationTool < MCP::Tool
  extend Pagy::Backend

  class << self
    def current_user(server_context)
      server_context.fetch(:current_user)
    end

    def current_account(server_context)
      server_context.fetch(:current_account)
    end

    # Standard pagination wrapper used by every *_list tool.
    def paginate(scope, page: 1, per_page: 25)
      per_page = per_page.to_i.clamp(1, 100)
      pagy_obj, records = pagy(scope, page: page.to_i, items: per_page)
      pagination = {
        page: pagy_obj.page,
        items: pagy_obj.items,
        count: pagy_obj.count,
        pages: pagy_obj.pages,
        from: pagy_obj.from,
        to: pagy_obj.to,
        prev: pagy_obj.prev,
        next: pagy_obj.next,
        last: pagy_obj.last
      }
      [records, pagination]
    end

    # Uniform JSON-text envelope so list/show tools all speak the same shape.
    def json_response(payload)
      MCP::Tool::Response.new([{ type: 'text', text: payload.to_json }])
    end

    def text_response(message)
      MCP::Tool::Response.new([{ type: 'text', text: message }])
    end

    # Wraps the tool body and converts common ActiveRecord failures into
    # readable text responses. Replaces the previous Mcp::Concerns::RequestExceptionHandler.
    def handle_errors
      yield
    rescue ActiveRecord::RecordNotFound => e
      text_response(e.message)
    rescue ActiveRecord::RecordInvalid => e
      text_response("Validation failed: #{e.record.errors.full_messages.join(', ')}")
    rescue StandardError => e
      # Avoid leaking internal details (SQL fragments, stack-adjacent info) to
      # the LLM client. The full exception goes to the Rails logger / Sentry.
      text_response('An internal error occurred while running this tool.')
    end
  end
end
