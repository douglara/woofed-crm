# frozen_string_literal: true

# MCP entry point. Streamable HTTP transport per the MCP 2025-06-18 spec —
# a single endpoint handling both POST (JSON-RPC requests) and GET (server
# stream init). See docs/mcp/authentication.md and docs/mcp/architecture.md.
class McpController < ActionController::API
  before_action -> { doorkeeper_authorize! :mcp }
  before_action :validate_token_audience!

  def handle
    if params[:method] == 'notifications/initialized'
      head(:accepted) and return
    end

    render(json: mcp_server.handle_json(request.body.read))
  end

  private

  # RFC 8707: a token issued for `<base>/mcp` cannot be reused against other
  # resources, even if the scope is right. Rejects tokens without a resource
  # binding too — generate Claude Desktop tokens with `resource: '<base>/mcp'`.
  def validate_token_audience!
    return if doorkeeper_token.resource == "#{request.base_url}/mcp"

    render json: {
      error: 'invalid_token',
      error_description: 'Token not valid for this resource'
    }, status: :unauthorized
  end

  def mcp_server
    user = User.find(doorkeeper_token.resource_owner_id)
    context = {
      current_user:    user,
      current_account: user.account,
      token:           doorkeeper_token
    }

    server = MCP::Server.new(
      name: 'woofed-crm',
      version: '1.0.0',
      tools: ApplicationTool.descendants,
      resource_templates: ApplicationResource.descendants.map(&:to_resource_template),
      server_context: context
    )

    # MCP::ResourceTemplate is metadata-only; dispatch reads to the descendant
    # whose `uri_template` matches the request URI (see ApplicationResource.read).
    server.resources_read_handler do |params|
      ApplicationResource.read(params[:uri], server_context: context)
    end

    server
  end
end
