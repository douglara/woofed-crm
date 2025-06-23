# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Webhook::ApiClient, type: :model do
  let(:webhook) { build(:webhook, :skip_validate, url: 'https://example.com/webhook') }
  subject { described_class.new(webhook) }
  let(:request_headers) { { 'Content-Type' => 'application/json' } }

  describe '#get_request' do
    let(:response_body) { {}.to_json }

    context 'when the request is successful' do
      before do
        stub_request(:post, 'https://example.com/webhook')
          .to_return(status: 200, body: response_body, headers: request_headers)
      end

      it 'returns response status with :ok key' do
        result = subject.post_request
        expect(result[:ok]).to eq(200)
        expect(result[:request].status).to eq(200)
      end
    end

    context 'when the request fails' do
      before do
        stub_request(:post, 'https://example.com/webhook')
          .to_return(status: 404, body: response_body, headers: request_headers)
      end

      it 'returns error with :error key' do
        result = subject.post_request
        expect(result[:error]).to eq('Invalid or unreachable URL (status: 404)')
        expect(result[:request].status).to eq(404)
      end

      it 'logs the error' do
        expect(Rails.logger).to receive(:error).with(/Webhook Api Client error: Failed to validate webhook URL - Webhook new/)
        expect(Rails.logger).to receive(:error).with(/Webhook: #{webhook.inspect}/)
        expect(Rails.logger).to receive(:error).with(/Request: .*status=404/)
        subject.post_request
      end
    end

    context 'when the response body is empty on error' do
      before do
        stub_request(:post, 'https://example.com/webhook')
          .to_return(status: 500, body: response_body, headers: request_headers)
      end

      it 'returns error with status code' do
        result = subject.post_request
        expect(result[:error]).to eq('Invalid or unreachable URL (status: 500)')
        expect(result[:request].status).to eq(500)
      end
    end
  end
end
