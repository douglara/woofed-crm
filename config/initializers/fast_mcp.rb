require Rails.root.join('lib/mcp/jwt_authenticator').to_s

FastMcp.mount_in_rails(
  Rails.application,
  name: 'woofed-crm',
  version: '1.0.0',
  path_prefix: '/mcp',
  messages_route: 'messages',
  sse_route: 'sse'
) do |server|
  Rails.application.config.after_initialize do
    server.register_tools(*ApplicationTool.descendants)
    server.register_resources(*ApplicationResource.descendants)
  end
end

Rails.application.config.middleware.insert_before(
  FastMcp::Transports::RackTransport,
  Mcp::JwtAuthenticator,
  path_prefix: '/mcp'
)
