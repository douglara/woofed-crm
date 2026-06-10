# spec/models/woofed_ai_spec.rb

require 'rails_helper'

RSpec.describe WoofedAi, type: :model do
  let!(:account) { create(:account) }
  let(:user) { create(:user) }
  let(:agent_url) { 'http://woofed-ai.test' }

  subject { described_class.new(user) }

  # WoofedAi reads the agent endpoint and the static Bearer secret from the
  # environment; every example needs them present (and restored afterwards).
  around do |example|
    previous = ENV.values_at('WOOFED_AI_URL', 'OS_SECURITY_KEY')
    ENV['WOOFED_AI_URL'] = agent_url
    ENV['OS_SECURITY_KEY'] = 'os-secret'
    example.run
    ENV['WOOFED_AI_URL'], ENV['OS_SECURITY_KEY'] = previous
  end

  # A fully configured agent: an enabled assistant with model + LLM key. The
  # user already owns an MCP token (minted on create), so this is all that is
  # missing for `available?` to be true.
  def enable_assistant!
    create(:apps_ai_assistent, enabled: true, api_key: 'llm-key', model: 'gpt-4o')
  end

  def stub_agents
    stub_request(:get, "#{agent_url}/agents")
      .to_return(status: 200, body: [{ id: described_class::AGENT_ID, db_id: 'db-1' }].to_json)
  end

  describe '#available?' do
    context 'when it is true' do
      let!(:assistant) { enable_assistant! }

      it 'is true when endpoint, secret, enabled assistant, LLM key, model and MCP token are present' do
        expect(subject.available?).to be(true)
      end
    end

    context 'when it is false' do
      it 'is false when the agent endpoint is missing' do
        enable_assistant!
        ENV['WOOFED_AI_URL'] = ''

        expect(subject.available?).to be(false)
      end

      it 'is false when the security key is missing' do
        enable_assistant!
        ENV['OS_SECURITY_KEY'] = ''

        expect(subject.available?).to be(false)
      end

      it 'is false when there is no assistant configured' do
        expect(subject.available?).to be(false)
      end

      it 'is false when the assistant is disabled' do
        create(:apps_ai_assistent, enabled: false, api_key: 'llm-key', model: 'gpt-4o')

        expect(subject.available?).to be(false)
      end

      it 'is false when the user has no MCP token' do
        enable_assistant!
        user.access_tokens.update_all(revoked_at: Time.current)

        expect(subject.available?).to be(false)
      end
    end
  end

  describe '#model' do
    context 'when an assistant exists' do
      let!(:assistant) { create(:apps_ai_assistent, model: 'gpt-4o') }

      it 'returns the assistant model' do
        expect(subject.model).to eq('gpt-4o')
      end
    end

    it 'returns nil when there is no assistant' do
      expect(subject.model).to be_nil
    end
  end

  describe '#latest_session' do
    it 'returns the first (newest) session the agent lists for the current user' do
      stub_request(:get, "#{agent_url}/sessions")
        .with(query: hash_including(
          'type' => 'agent',
          'component_id' => described_class::AGENT_ID,
          'user_id' => user.id.to_s,
          'sort_by' => 'created_at',
          'sort_order' => 'desc',
          'limit' => '1'
        ))
        .to_return(status: 200, body: { data: [
          { 'session_id' => 'sess-newest', 'created_at' => 2 },
          { 'session_id' => 'sess-older', 'created_at' => 1 }
        ] }.to_json)

      expect(subject.latest_session).to eq('session_id' => 'sess-newest', 'created_at' => 2)
    end

    it 'returns nil when the user has no sessions' do
      stub_request(:get, "#{agent_url}/sessions")
        .with(query: hash_including({}))
        .to_return(status: 200, body: { data: [] }.to_json)

      expect(subject.latest_session).to be_nil
    end

    it 'returns nil when the agent responds with an error status' do
      stub_request(:get, "#{agent_url}/sessions")
        .with(query: hash_including({})).to_return(status: 500)

      expect(subject.latest_session).to be_nil
    end

    it 'returns nil when the connection fails' do
      stub_request(:get, "#{agent_url}/sessions")
        .with(query: hash_including({})).to_timeout

      expect(subject.latest_session).to be_nil
    end

    it 'returns nil when the body is not valid JSON' do
      stub_request(:get, "#{agent_url}/sessions")
        .with(query: hash_including({})).to_return(status: 200, body: 'not json')

      expect(subject.latest_session).to be_nil
    end
  end

  describe '#session_runs' do
    it 'returns an empty array when the session id is blank' do
      expect(subject.session_runs('')).to eq([])
    end

    it 'returns the runs of the session, forwarding the resolved db_id' do
      stub_agents
      stub_request(:get, "#{agent_url}/sessions/sess-1/runs")
        .with(query: hash_including('type' => 'agent', 'db_id' => 'db-1'))
        .to_return(status: 200, body: [{ 'run_input' => 'Hello', 'content' => 'Hi' }].to_json)

      expect(subject.session_runs('sess-1')).to eq([{ 'run_input' => 'Hello', 'content' => 'Hi' }])
    end

    it 'returns an empty array when the agent responds with an error status' do
      stub_agents
      stub_request(:get, "#{agent_url}/sessions/sess-1/runs")
        .with(query: hash_including({})).to_return(status: 500)

      expect(subject.session_runs('sess-1')).to eq([])
    end

    it 'returns an empty array when the connection fails' do
      stub_agents
      stub_request(:get, "#{agent_url}/sessions/sess-1/runs")
        .with(query: hash_including({})).to_timeout

      expect(subject.session_runs('sess-1')).to eq([])
    end

    it 'returns an empty array when the body is not valid JSON' do
      stub_agents
      stub_request(:get, "#{agent_url}/sessions/sess-1/runs")
        .with(query: hash_including({})).to_return(status: 200, body: 'not json')

      expect(subject.session_runs('sess-1')).to eq([])
    end
  end

  describe '#stream_run' do
    let!(:assistant) { enable_assistant! }

    it 'streams each response chunk and forwards the factory_input secrets' do
      stub_request(:post, "#{agent_url}/agents/#{described_class::AGENT_ID}/runs")
        .to_return(status: 200, body: '{"event":"RunCompleted","content":"Hi"}')

      chunks = []
      subject.stream_run(message: 'Hello', session_id: 'sess-1') { |chunk| chunks << chunk }

      expect(chunks.join).to include('RunCompleted').and include('Hi')
      expect(
        a_request(:post, "#{agent_url}/agents/#{described_class::AGENT_ID}/runs").with { |req|
          req.body.include?('factory_input') &&
            req.body.include?('llm-key') &&
            req.body.include?('gpt-4o') &&
            req.body.include?(CGI.escape(user.woofed_ai_token)) &&
            req.body.include?("user_id=#{user.id}") &&
            req.body.include?('session_id=sess-1')
        }
      ).to have_been_made
    end
  end

  describe '#db_id' do
    it 'returns the db_id of the matching agent' do
      stub_agents

      expect(subject.send(:db_id)).to eq('db-1')
    end

    it 'returns nil when no agent matches the agent id' do
      stub_request(:get, "#{agent_url}/agents")
        .to_return(status: 200, body: [{ id: 'other-agent', db_id: 'db-9' }].to_json)

      expect(subject.send(:db_id)).to be_nil
    end

    it 'returns nil when the agents endpoint responds with an error status' do
      stub_request(:get, "#{agent_url}/agents").to_return(status: 500)

      expect(subject.send(:db_id)).to be_nil
    end

    it 'returns nil when the connection fails' do
      stub_request(:get, "#{agent_url}/agents").to_timeout

      expect(subject.send(:db_id)).to be_nil
    end
  end
end
