require 'rails_helper'
require 'inertia_rails/rspec'

RSpec.describe Inertia::Accounts::WoofedAisController, type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user) }
  let(:agent_url) { 'http://woofed-ai.test' }
  let(:base_url) { "/accounts/#{account.id}/woofed_ai" }

  around do |example|
    previous = ENV.values_at('WOOFED_AI_URL', 'OS_SECURITY_KEY')
    ENV['WOOFED_AI_URL'] = agent_url
    ENV['OS_SECURITY_KEY'] = 'os-secret'
    example.run
    ENV['WOOFED_AI_URL'], ENV['OS_SECURITY_KEY'] = previous
  end

  # Enabled assistant + the user's minted MCP token = a fully configured agent.
  def configure_agent!
    create(:apps_ai_assistent, enabled: true, api_key: 'llm-key', model: 'gpt-4o')
  end

  def stub_agents
    stub_request(:get, "#{agent_url}/agents")
      .to_return(status: 200, body: [{ id: 'woofed-ai-agent', db_id: 'db-1' }].to_json)
  end

  describe 'GET /accounts/{account.id}/woofed_ai' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get base_url
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before { sign_in(user) }

      context 'when the agent is configured' do
        before do
          configure_agent!
          stub_agents
          stub_request(:get, "#{agent_url}/sessions")
            .with(query: hash_including('user_id' => user.id.to_s, 'component_id' => 'woofed-ai-agent'))
            .to_return(status: 200, body: { data: [{ session_id: 'sess-1' }] }.to_json)
          stub_request(:get, "#{agent_url}/sessions/sess-1/runs")
            .with(query: hash_including('type' => 'agent'))
            .to_return(status: 200, body: [
              { run_input: 'Hello', content: 'Hi there', created_at: 1 }
            ].to_json)
        end

        it 'renders the chat with the latest session and its history' do
          get base_url

          expect(response).to have_http_status(:success)
          expect(inertia).to render_component('WoofedAi/Chat')
          expect(inertia).to have_props(
            session_id: 'sess-1',
            agent_available: true,
            model: 'gpt-4o'
          )
          expect(inertia.props[:initial_runs].first).to include('run_input' => 'Hello')
        end
      end

      context 'when the agent is not configured' do
        it 'renders the chat as unavailable with no history' do
          get base_url

          expect(response).to have_http_status(:success)
          expect(inertia).to have_props(agent_available: false, initial_runs: [])
        end
      end
    end
  end

  describe 'POST /accounts/{account.id}/woofed_ai/create_session' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "#{base_url}/create_session"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before { sign_in(user) }

      it 'redirects to the chat on a freshly generated session id' do
        post "#{base_url}/create_session"

        location = response.headers['Location']
        expect(location).to include(base_url)
        expect(location).to match(/session_id=[0-9a-f-]{36}/)
      end
    end
  end

  describe 'POST /accounts/{account.id}/woofed_ai/create_message' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "#{base_url}/create_message", params: { message: 'Hello' }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        configure_agent!
        sign_in(user)
        stub_agents
      end

      it 'streams the agent response chunks back, forwarding the factory_input' do
        stub_request(:post, "#{agent_url}/agents/woofed-ai-agent/runs")
          .to_return(status: 200, body: '{"event":"RunCompleted","content":"Hi"}')

        post "#{base_url}/create_message", params: { message: 'Hello', session_id: 'sess-1' }

        expect(response.headers['Content-Type']).to include('application/x-ndjson')
        expect(response.body).to include('RunCompleted').and include('Hi')
        expect(
          a_request(:post, "#{agent_url}/agents/woofed-ai-agent/runs")
            .with { |req| req.body.include?('factory_input') && req.body.include?('llm-key') }
        ).to have_been_made
      end

      it 'emits a RunError chunk when the agent call fails' do
        stub_request(:post, "#{agent_url}/agents/woofed-ai-agent/runs").to_timeout

        post "#{base_url}/create_message", params: { message: 'Hello', session_id: 'sess-1' }

        expect(response.body).to include('RunError')
      end
    end
  end
end
