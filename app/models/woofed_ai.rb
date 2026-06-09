# frozen_string_literal: true

# Server-side client for the Woofed AI agent (agno AgentOS, see
# docs/ai-agent/architecture.md). It assembles the per-request `factory_input`
# (model + LLM key from `Apps::AiAssistent`, MCP token from the user) and the
# static `OS_SECURITY_KEY` Bearer token so none of those secrets ever reach the
# browser — the Rails controller proxies every call through this object.
class WoofedAi
  AGENT_ID = 'woofed-ai-agent'

  def initialize(user)
    @user = user
    @assistant = Apps::AiAssistent.first
  end

  # The agent can serve a run only when it is configured end to end: the
  # assistant is enabled with a model + LLM key, the user has an MCP token, and
  # the agent endpoint/secret are present in the environment.
  def available?
    return false unless base_url.present? && security_key.present?
    return false unless @assistant&.enabled?

    @assistant.api_key.present? && @assistant.model.present? && mcp_token.present?
  end

  def model
    @assistant&.model
  end

  # The most recent session for this user, or nil. Mirrors agent-ui: filter the
  # agno sessions list by user_id and take the newest by created_at.
  def latest_session
    response = connection.get('/sessions') do |req|
      req.params['type'] = 'agent'
      req.params['component_id'] = AGENT_ID
      req.params['user_id'] = @user.id.to_s
      req.params['sort_by'] = 'created_at'
      req.params['sort_order'] = 'desc'
      req.params['limit'] = 1
    end
    return nil unless response.success?

    Array(JSON.parse(response.body)['data']).first
  rescue Faraday::Error, JSON::ParserError
    nil
  end

  # The runs (chat history) of a session, as returned by agno. Shape matches
  # agent-ui's getSessionAPI, consumed by the ported useSessionLoader mapping.
  def session_runs(session_id)
    return [] if session_id.blank?

    response = connection.get("/sessions/#{session_id}/runs") do |req|
      req.params['type'] = 'agent'
      req.params['db_id'] = db_id if db_id.present?
    end
    return [] unless response.success?

    Array(JSON.parse(response.body))
  rescue Faraday::Error, JSON::ParserError
    []
  end

  # Streams a run, yielding each raw body chunk as it arrives so the controller
  # can relay it straight to the browser via ActionController::Live.
  def stream_run(message:, session_id:, &on_chunk)
    connection.post("/agents/#{AGENT_ID}/runs") do |req|
      req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
      req.body = URI.encode_www_form(
        message: message,
        user_id: @user.id.to_s,
        session_id: session_id.to_s,
        stream: 'true',
        factory_input: factory_input.to_json
      )
      req.options.on_data = proc { |chunk, _overall_bytes| on_chunk.call(chunk) }
    end
  end

  private

  def db_id
    return @db_id if defined?(@db_id)

    response = connection.get('/agents')
    agents = response.success? ? Array(JSON.parse(response.body)) : []
    @db_id = agents.find { |agent| agent['id'] == AGENT_ID }&.dig('db_id')
  rescue Faraday::Error, JSON::ParserError
    @db_id = nil
  end

  def factory_input
    { mcp_token: mcp_token, llm_token: @assistant.api_key, llm_model: @assistant.model }
  end

  def mcp_token
    @mcp_token ||= @user.woofed_ai_token
  end

  def base_url
    ENV['WOOFED_AI_URL']
  end

  def security_key
    ENV['OS_SECURITY_KEY']
  end

  def connection
    @connection ||= Faraday.new(url: base_url) do |conn|
      conn.headers['Authorization'] = "Bearer #{security_key}"
      conn.options.timeout = 120
      conn.adapter Faraday.default_adapter
    end
  end
end
