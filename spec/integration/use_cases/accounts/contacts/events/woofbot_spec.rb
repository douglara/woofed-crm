# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Accounts::Contacts::Events::Woofbot, type: :request do
  before do
    stub_request(:post, /embeddings/)
      .to_return(status: 200, body: File.read('spec/integration/use_cases/accounts/create/mock_docs_site/intro_embedding.json'))

    stub_request(:post, /completions/)
      .to_return(status: 200, body: '{"id":"chatcmpl-1KF6fcWfWrvQfNODnXVsI6UrEFfgD","object":"chat.completion","created":1714611657,"model":"gpt-4-turbo-2024-04-09","choices":[{"index":0,"message":{"role":"assistant","content":"{\"response\": \"https://www.postman.com/dark-shuttle-5185/workspace/woofed-crm-api/collection/905262-e0bb0d71-a634-4fa2-8b03-4ae4c6dde690\", \"confidence\": 1}"},"logprobs":null,"finish_reason":"stop"}],"usage":{"prompt_tokens":1419,"completion_tokens":37,"total_tokens":1456},"system_fingerprint":"fp_ea6eb10039"}', headers: { 'Content-Type' => 'application/json' })

    stub_request(:post, /sendText/)
      .to_return(body: File.read('spec/integration/use_cases/accounts/apps/evolution_api/message/send_text_response.json'), status: 201, headers: { 'Content-Type' => 'application/json' })
  end

  subject { described_class.new(event) }

  let(:account) { create(:account, woofbot_auto_reply: true) }
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
