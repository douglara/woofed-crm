# frozen_string_literal: true

class Inertia::Accounts::WoofedAisController < Inertia::InternalController
  include ActionController::Live

  def show
    client = WoofedAi.new(current_user)
    agent_available = client.available?
    session_id = agent_available ? current_session_id(client) : nil
    runs = agent_available ? client.session_runs(session_id) : []

    render inertia: 'WoofedAi/Chat', props: {
      session_id: session_id,
      initial_runs: runs,
      agent_available: agent_available,
      model: client.model
    }
  end

  # Starts a fresh session: a new id is generated and the page reloads blank on
  # it. The previous session is left untouched in the agent but no longer
  # surfaced — the user only ever works on the latest session.
  def create_session
    redirect_to account_woofed_ai_path(Current.account, session_id: SecureRandom.uuid)
  end

  # Proxies a streaming run to the agent, relaying every chunk straight to the
  # browser so the React client can render tokens as they arrive.
  def create_message
    response.headers['Content-Type'] = 'application/x-ndjson'
    response.headers['Cache-Control'] = 'no-cache'
    response.headers['X-Accel-Buffering'] = 'no'
    response.headers.delete('Content-Length')

    WoofedAi.new(current_user).stream_run(
      message: params[:message],
      session_id: params[:session_id]
    ) { |chunk| response.stream.write(chunk) }
  rescue StandardError => e
    response.stream.write({ event: 'RunError', content: e.message }.to_json)
  ensure
    response.stream.close
  end

  private

  # Prefer an explicit id (set right after "New session"); otherwise fall back to
  # the user's most recent session in the agent.
  def current_session_id(client)
    params[:session_id].presence || client.latest_session&.dig('session_id')
  end
end
