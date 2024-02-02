require 'rails_helper'
require 'webmock/rspec'
require 'sidekiq/testing'

RSpec.describe Apps::EvolutionApisController, type: :request do
  let(:account) { create(:account) }
  let(:delete_instance_response) do
    File.read('spec/integration/use_cases/accounts/apps/evolution_api/instance/delete_response.json')
  end

  def qrcode_updated_webhook_event_params(evolution_api)
    {
      "event": 'qrcode.updated',
      "instance": evolution_api.instance,
      "data": {
        "qrcode": {
          "instance": evolution_api.instance,
          "pairingCode": 'V37R3T7X',
          "code": '2@xCLTLQpXqmnR1jld2wKbVGmXchdVSFR3QHQa+6BNF8EK8VeoKUTYklFySHt0rrgknAPgwBkD7y1IIQ==,Xl787d38Gmn0wbPMtlvd47VIqs1xzfsZQTTLgePiYmA=,XQTEs9Fx080JHolGhWrlheRKQo8WCPj0DqCbrrMLiU8=,r8hWahUUJqu7BJFq1l1dQopW2r3lEbOrWOyQJfmmZdY=',
          "base64": 'qrcode'
        }
      },
      "destination": 'https://webhook.com/',
      "date_time": '2024-01-27T02:35:43.230Z',
      "server_url": 'https://server.com',
      "apikey": evolution_api.token
    }
  end

  def connection_event_params(evolution_api, status_reason, status = 'open')
    {
      "event": 'connection.update',
      "instance": evolution_api.instance,
      "data": {
        "instance": evolution_api.instance,
        "state": status,
        "statusReason": status_reason
      },
      "destination": 'https://webhook.com/',
      "date_time": '2024-01-27T01:19:47.979Z',
      "sender": '5522999999999@s.whatsapp.net',
      "server_url": 'https://app-beta.woofedcrm.com/',
      "apikey": evolution_api.token
    }
  end

  def post_webhook(event_data)
    Sidekiq::Testing.inline! { post '/apps/evolution_apis/webhooks', params: event_data }
  end

  def expect_success
    expect(response).to have_http_status(200)
    expect(JSON.parse(response.body)).to eq({ 'ok' => true })
  end

  describe 'POST /apps/evolution_apis/webhooks' do
    describe 'when evolution_api is connecting' do
      let!(:evolution_api_connecting) { create(:apps_evolution_api, :connecting, account: account) }
      context 'when is qrcode_update event ' do
        it 'should update qrcode' do
          expect do
            post_webhook(qrcode_updated_webhook_event_params(evolution_api_connecting))
          end.to change { evolution_api_connecting.reload.qrcode }
          expect_success
        end
      end
      context 'when is created_connection event' do
        it 'should update evolution_api status, phone and qrcode' do
          post_webhook(connection_event_params(evolution_api_connecting, 200))
          expect_success
          expect(evolution_api_connecting.reload.connected?).to be_truthy
          expect(evolution_api_connecting.phone).to be_present
          expect(evolution_api_connecting.qrcode).not_to be_present
        end
      end
      context 'when is deleted_connection event' do
        it 'should update evolution_api status' do
          stub_request(:delete, /delete/)
            .to_return(body: delete_instance_response.to_json, status: 200, headers: { 'Content-Type' => 'application/json' })
          post_webhook(connection_event_params(evolution_api_connecting, 401))
          expect_success
          expect(evolution_api_connecting.reload.connection_status).to be_truthy
        end
      end
    end
    describe 'when evolution_api is connected' do
      let!(:evolution_api_connected) { create(:apps_evolution_api, :connected, account: account) }
      context 'when is qrcode_update event' do
        it 'evolution_api should not be changed' do
          post_webhook(qrcode_updated_webhook_event_params(evolution_api_connected))
          expect_success
          expect(evolution_api_connected.reload.changed?).to be_falsey
        end
      end
      context 'when is deleted_connection event' do
        it 'should update evolution_api status' do
          stub_request(:delete, /delete/)
            .to_return(body: delete_instance_response.to_json, status: 200, headers: { 'Content-Type' => 'application/json' })
          post_webhook(connection_event_params(evolution_api_connected, 401, 'close'))
          expect_success
          expect(evolution_api_connected.reload.disconnected?).to be_truthy
        end
      end
    end
    describe 'when evolution_api is disconnected' do
      let!(:evolution_api) { create(:apps_evolution_api, account: account) }
      context 'when is qrcode_update event' do
        it 'evolution_api should not be changed' do
          post_webhook(qrcode_updated_webhook_event_params(evolution_api))
          expect_success
          expect(evolution_api.reload.changed?).to be_falsey
        end
      end
      context 'when is deleted_connection event' do
        it 'evolution_api should not be changed' do
          post_webhook(connection_event_params(evolution_api, 401, 'close'))
          expect_success
          expect(evolution_api.reload.changed?).to be_falsey
        end
      end
    end
  end
end
