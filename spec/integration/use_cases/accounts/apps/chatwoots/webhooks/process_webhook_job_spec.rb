# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Accounts::Apps::Chatwoots::Webhooks::ProcessWebhookJob, type: :request do
  describe 'queue distribution' do
    let(:account_1) { create(:account) }
    let(:account_2) { create(:account) }
    let(:chatwoot_1) { create(:apps_chatwoots, :skip_validate, embedding_token: 'token_1', account: account_1) }
    let(:chatwoot_2) { create(:apps_chatwoots, :skip_validate, embedding_token: 'token_2', account: account_2) }

    let(:chatwoot_event) do
      JSON.parse(File.read('spec/integration/use_cases/accounts/apps/chatwoots/webhooks/events/message/event_message_receive.json'))
    end

    around(:each) do |example|
      orig_value = ENV['GOOD_JOB_EXECUTION_MODE']
      ENV['GOOD_JOB_EXECUTION_MODE'] = 'external'
      example.run
    ensure
      ENV['GOOD_JOB_EXECUTION_MODE'] = orig_value
    end

    let(:contact_response) do
      File.read('spec/integration/use_cases/accounts/apps/chatwoots/webhooks/events/response_contact.json')
    end
    let(:response_conversations) do
      File.read('spec/integration/use_cases/accounts/apps/chatwoots/webhooks/events/response_conversations.json')
    end

    before do
      stub_request(:get, /contacts/)
        .to_return(body: contact_response, status: 200, headers: { 'Content-Type' => 'application/json' })
      stub_request(:get, /labels/)
        .to_return(body: { "payload": ['testc'] }.to_json, status: 200, headers: { 'Content-Type' => 'application/json' })
      stub_request(:get, /conversations/)
        .to_return(body: response_conversations, status: 200, headers: { 'Content-Type' => 'application/json' })
    end

    it 'should run max 1 concurrency jobs peer chatwoot app' do
      10.times do
        Accounts::Apps::Chatwoots::Webhooks::ProcessWebhookJob.perform_later(
          chatwoot_event.merge({ 'token': chatwoot_1.embedding_token }).to_json, chatwoot_1.embedding_token
        )
        Accounts::Apps::Chatwoots::Webhooks::ProcessWebhookJob.perform_later(
          chatwoot_event.merge({ 'token': chatwoot_1.embedding_token }).to_json, chatwoot_2.embedding_token
        )
      end
      jobs = GoodJob::Job.all.order(finished_at: :asc)
      GoodJob.perform_inline

      expect(jobs.count).to eq(20)
      expect(jobs[4].concurrency_key).to include('token_1')
      expect(jobs[5].concurrency_key).to include('token_2')
      expect(jobs[6].concurrency_key).to include('token_1')
      expect(jobs[7].concurrency_key).to include('token_2')
    end
  end
end
