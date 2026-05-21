# frozen_string_literal: true

# Request helpers for MCP tool/resource specs. The new Streamable HTTP transport
# returns the JSON-RPC response directly in the HTTP body (no SSE mock needed).
module McpRequestHelpers
  MCP_RESOURCE_URL = 'http://www.example.com/mcp'

  def mcp_tool_call_body(tool_name, arguments = {})
    { jsonrpc: '2.0', method: 'tools/call',
      params: { name: tool_name, arguments: arguments }, id: 1 }.to_json
  end

  def mcp_resource_read_body(uri)
    { jsonrpc: '2.0', method: 'resources/read', params: { uri: uri }, id: 1 }.to_json
  end

  def mcp_response
    JSON.parse(response.body)
  end

  def mcp_result
    payload = mcp_response
    raise payload['error'].inspect if payload['error']

    result = payload['result'] || {}
    contents = result['content'] || result['contents']
    text = contents&.first&.dig('text')
    raise "MCP tool returned error: #{text}" if result['isError']

    text.present? ? JSON.parse(text) : result
  end

  # Plain text from the tool/resource response — used for error-path specs
  # where the body is a human-readable message, not JSON.
  def mcp_text
    payload = mcp_response
    result = payload['result'] || {}
    contents = result['content'] || result['contents']
    contents&.first&.dig('text')
  end

  # Issues a Doorkeeper access token bound to the test request base_url so it
  # passes McpController#validate_token_audience!. Same shape Claude Web gets
  # via OAuth, just minted directly to keep specs focused.
  def mcp_access_token_for(user, resource: MCP_RESOURCE_URL)
    application = Doorkeeper::Application.find_or_create_by!(name: 'Spec Client') do |app|
      app.redirect_uri = 'urn:ietf:wg:oauth:2.0:oob'
      app.scopes = 'mcp'
      app.confidential = true
    end
    Doorkeeper::AccessToken.create!(
      application: application,
      resource_owner_id: user.id,
      scopes: 'mcp',
      resource: resource
    ).token
  end

  def mcp_auth_headers(user)
    { 'Authorization' => "Bearer #{mcp_access_token_for(user)}",
      'Content-Type'  => 'application/json' }
  end
end

RSpec.configure do |config|
  config.include McpRequestHelpers, type: :request
end
