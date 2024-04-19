require 'rails_helper'
require 'webmock/rspec'

RSpec.describe Accounts::Apps::EvolutionApis::Instance::Create, type: :request do
  describe '.call' do
    let(:account) { create(:account) }
    let(:evolution_api) { create(:apps_evolution_api, account: account) }
    let(:create_instance_response_unauthorized) do
      {
        "status": 401,
        "error": 'Unauthorized',
        "response": {
          "message": 'Unauthorized'
        }
      }.to_json
    end

    def create_instance_response(evolution_api)
      {
        "instance": {
          "instanceName": evolution_api.instance,
          "instanceId": 'f9618261-c32b-462f-a1ed-0f6b6e334df5',
          "status": 'created'
        },
        "hash": {
          "apikey": evolution_api.token
        },
        "webhook": {},
        "websocket": {},
        "rabbitmq": {},
        "sqs": {},
        "typebot": {
          "enabled": false
        },
        "settings": {
          "reject_call": false,
          "msg_call": '',
          "groups_ignore": true,
          "always_online": false,
          "read_messages": false,
          "read_status": false
        },
        "qrcode": {
          "pairingCode": 'XXX5ZREX',
          "code": '2@5qoE7bYDeYAjTSug0bmUlFmziMV+rfNsV5MHaomX2aG/pB7+50GnMnVOCvTMiOYx2KHgqIkVLPMwcg==,cA3buwyd1UloB5EBhI/PwLlhnBIp9qSWGgflcHvWtxg=,HVqYWiuUbUb1c1bu+7YUBYpDT3o95GrG+FVpItey1AU=,KPH54eCvRpsAP7OvxLZHmQyMeiAUBcZeij14ws2pLAE=',
          "base64": 'qrcode',
          "count": 1
        }
      }.to_json
    end

    describe 'success' do
      before do
        stub_request(:post, /instance/)
          .to_return(body: create_instance_response(evolution_api), status: 201, headers: { 'Content-Type' => 'application/json' })
        stub_request(:post, /settings/)
          .to_return(status: 200, body: '{"settings":{"instanceName":"3d3841c43940e8e60704","settings":{"reject_call":false,"groups_ignore":false,"always_online":false,"read_messages":false,"read_status":false}}}',
                     headers: { 'Content-Type' => 'application/json' })
      end
      it 'create instance' do
        result = described_class.call(evolution_api)
        expect(result.key?(:ok)).to eq(true)
      end
    end
    describe 'failed' do
      context 'when user is unauthorized' do
        before do
          stub_request(:post, /instance/)
            .to_return(body: create_instance_response_unauthorized, status: 401, headers: { 'Content-Type' => 'application/json' })
        end
        it 'should return error message' do
          result = described_class.call(evolution_api)
          expect(result.key?(:error)).to eq(true)
        end
      end
    end
  end
end
