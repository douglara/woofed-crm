# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Accounts::Contacts::Events::GenerateAiResponse, type: :request do
  subject { described_class.new(event) }

  let!(:account) { create(:account) }
  let!(:contact) { create(:contact, account: account) }
  let!(:event) { create(:event, account: account, contact: contact, from_me: false, content: 'Qual o link da API?') }

  context '#call' do
    before do
      stub_request(:post, /embeddings/)
        .to_return(status: 200, body: File.read('spec/integration/use_cases/accounts/create/mock_docs_site/intro_embedding.json'))
    end
    it 'should generate ai response' do
      stub_request(:post, /completions/)
        .to_return(status: 200, body: '{"id":"chatcmpl-1KF6fcWfWrvQfNODnXVsI6UrEFfgD","object":"chat.completion","created":1714611657,"model":"gpt-4-turbo-2024-04-09","choices":[{"index":0,"message":{"role":"assistant","content":"{\"response\": \"https://www.postman.com/dark-shuttle-5185/workspace/woofed-crm-api/collection/905262-e0bb0d71-a634-4fa2-8b03-4ae4c6dde690\", \"confidence\": 1}"},"logprobs":null,"finish_reason":"stop"}],"usage":{"prompt_tokens":1419,"completion_tokens":37,"total_tokens":1456},"system_fingerprint":"fp_ea6eb10039"}', headers: { 'Content-Type' => 'application/json' })

      result = subject.call
      expect(result).to eq('https://www.postman.com/dark-shuttle-5185/workspace/woofed-crm-api/collection/905262-e0bb0d71-a634-4fa2-8b03-4ae4c6dde690')
    end

    it 'should regex markdown format' do
      stub_request(:post, /completions/)
        .to_return(status: 200, body: '{"id":"chatcmpl-9KHbdv38KWI1IGuFdqs7nBm2owXtE","object":"chat.completion","created":1714621265,"model":"gpt-4-turbo-2024-04-09","choices":[{"index":0,"message":{"role":"assistant","content":"```json\n{\n  \"response\": \"https://www.postman.com/dark-shuttle-5185/workspace/woofed-crm-api/collection/905262-e0bb0d71-a634-4fa2-8b03-4ae4c6dde690\",\n  \"confidence\": 1\n}\n```"},"logprobs":null,"finish_reason":"stop"}],"usage":{"prompt_tokens":2291,"completion_tokens":118,"total_tokens":2409},"system_fingerprint":"fp_ea6eb70039"}', headers: { 'Content-Type' => 'application/json' })

      result = subject.call
      expect(result).to eq('https://www.postman.com/dark-shuttle-5185/workspace/woofed-crm-api/collection/905262-e0bb0d71-a634-4fa2-8b03-4ae4c6dde690')
    end

    it 'when limit exceeded' do
      account.ai_usage['tokens'] = 16_676_667
      account.save
      stub_request(:post, /completions/)
        .to_return(status: 200, body: '{"id":"chatcmpl-9KHbdv38KWI1IGuFdqs7nBm2owXtE","object":"chat.completion","created":1714621265,"model":"gpt-4-turbo-2024-04-09","choices":[{"index":0,"message":{"role":"assistant","content":"```json\n{\n  \"response\": \"https://www.postman.com/dark-shuttle-5185/workspace/woofed-crm-api/collection/905262-e0bb0d71-a634-4fa2-8b03-4ae4c6dde690\",\n  \"confidence\": 1\n}\n```"},"logprobs":null,"finish_reason":"stop"}],"usage":{"prompt_tokens":2291,"completion_tokens":118,"total_tokens":2409},"system_fingerprint":"fp_ea6eb70039"}', headers: { 'Content-Type' => 'application/json' })

      result = subject.call
      expect(result).to eq('')
    end
  end
end
