# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Accounts::Contacts::Events::Woofbot, type: :request do
  before do
    stub_request(:post, /embeddings/)
      .to_return(status: 200, body: File.read('spec/integration/use_cases/accounts/create/mock_docs_site/intro_embedding.json'))

    stub_request(:post, /responses/)
      .to_return(status: 200, body: '{"id":"resp_680b0698508c8192b5c2ace28644777f017fec1c71b11bb6","object":"response","created_at":1745553048,"status":"completed","error":null,"incomplete_details":null,"instructions":null,"max_output_tokens":2048,"model":"gpt-4o-2024-08-06","output":[{"id":"msg_680b0698b2408192b651d57f613e20f9017fec1c71b11bb6","type":"message","status":"completed","content":[{"type":"output_text","annotations":[],"text":"{\"response\":\"https://www.postman.com/dark-shuttle-5185/workspace/woofed-crm-api/collection/905262-e0bb0d71-a634-4fa2-8b03-4ae4c6dde690\",\"confidence\":100}"}],"role":"assistant"}],"parallel_tool_calls":true,"previous_response_id":null,"reasoning":{"effort":null,"summary":null},"service_tier":"default","store":true,"temperature":0.3,"text":{"format":{"type":"json_schema","description":null,"name":"suggestion","schema":{"type":"object","properties":{"response":{"type":"string"},"confidence":{"type":"integer"}},"required":["response","confidence"],"additionalProperties":false},"strict":true}},"tool_choice":"auto","tools":[],"top_p":1,"truncation":"disabled","usage":{"input_tokens":1584,"input_tokens_details":{"cached_tokens":0},"output_tokens":44,"output_tokens_details":{"reasoning_tokens":0},"total_tokens":1628},"user":null,"metadata":{}}', headers: { 'Content-Type' => 'application/json' })

    stub_request(:post, /sendText/)
      .to_return(body: File.read('spec/integration/use_cases/accounts/apps/evolution_api/message/send_text_response.json'), status: 201, headers: { 'Content-Type' => 'application/json' })
  end

  subject { described_class.new(event) }

  let(:account) { create(:account) }
  let!(:ai_assistent) { create(:apps_ai_assistent, auto_reply: true) }
  let!(:user) { create(:user, account: account) }
  let(:contact) { create(:contact, account: account) }
  let!(:deal) { create(:deal, account: account, contact: contact) }
  let(:apps_evolution_apis) { create(:apps_evolution_api, account: account) }
  let(:event) do
    create(:event, deal: deal, app: apps_evolution_apis, kind: 'evolution_api_message', account: account,
                    contact: contact, from_me: false, content: 'Qual o link da API?')
  end

  context '#call' do
    it 'should generate ai response' do
      response_event = subject.call
      expect(response_event.content.to_s).to eq(
        "https://www.postman.com/dark-shuttle-5185/workspace/woofed-crm-api/collection/905262-e0bb0d71-a634-4fa2-8b03-4ae4c6dde690\n\n🤖 Mensagem automática"
      )
      expect(response_event.from_me).to eq(true)
    end
  end
end
