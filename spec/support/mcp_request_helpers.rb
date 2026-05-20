module McpRequestHelpers
  def mcp_tool_call_body(tool_name, arguments = {})
    { jsonrpc: '2.0', method: 'tools/call',
      params: { name: tool_name, arguments: arguments }, id: 1 }.to_json
  end

  def mcp_resource_read_body(uri)
    { jsonrpc: '2.0', method: 'resources/read', params: { uri: uri }, id: 1 }.to_json
  end

  def mcp_response
    payload = Thread.current[:mcp_captured_response]
    raise 'No MCP response was captured for this request' unless payload

    payload
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
end

RSpec.configure do |config|
  config.include McpRequestHelpers, type: :request

  config.before(:each, type: :request) do
    Thread.current[:mcp_captured_response] = nil
    allow_any_instance_of(FastMcp::Transports::RackTransport).to receive(:send_message) do |_, message|
      Thread.current[:mcp_captured_response] = JSON.parse(message.is_a?(String) ? message : JSON.generate(message))
    end
  end
end
