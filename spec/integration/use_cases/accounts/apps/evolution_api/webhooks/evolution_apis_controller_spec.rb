require 'rails_helper'
require 'webmock/rspec'
require 'sidekiq/testing'

RSpec.describe Apps::EvolutionApisController, type: :request do
  let(:account) { create(:account) }
  let(:qrcode_updated_webhook_event) { load_webhook_event('qrcode_updated_event.json') }
  let(:created_connection_event) { load_webhook_event('created_connection_event.json') }
  let(:deleted_connection_event) { load_webhook_event('deleted_connection_event.json') }
  let(:delete_instance_response) { File.read("spec/integration/use_cases/accounts/apps/evolution_api/instance/delete_response.json") }

  def load_webhook_event(filename)
    File.read(Rails.root.join('spec/integration/use_cases/accounts/apps/evolution_api/webhooks/events', filename))
  end

  def post_webhook(event_data)
    Sidekiq::Testing.inline! { post '/apps/evolution_apis/webhooks', params: JSON.parse(event_data) }
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
          post_webhook(qrcode_updated_webhook_event)
          expect_success
          expect(evolution_api_connecting.reload.qrcode).to eq('qrcode')
        end
      end
      context 'when is created_connection event' do
        it 'should update evolution_api status, phone and qrcode' do
          post_webhook(created_connection_event)
          expect_success
          expect(evolution_api_connecting.reload.connected?).to be_truthy
          expect(evolution_api_connecting.phone).to be_present
          expect(evolution_api_connecting.qrcode).not_to be_present
        end
      end
      context 'when is deleted_connection event' do
        it 'should update evolution_api status' do
          stub_request(:delete, /delete/)
          .to_return(body: delete_instance_response.to_json, status: 200, headers: {'Content-Type' => 'application/json'})
          post_webhook(deleted_connection_event)
          expect_success
          expect(evolution_api_connecting.reload.connection_status).to be_truthy
        end
      end
    end
    describe 'when evolution_api is connected' do
      let!(:evolution_api_connected) { create(:apps_evolution_api, :connected, account: account) }
      context 'when is qrcode_update event' do
        it 'evolution_api should not be changed' do
          post_webhook(qrcode_updated_webhook_event)
          expect_success
          expect(evolution_api_connected.reload.changed?).to be_falsey
        end
      end
      context 'when is deleted_connection event' do
        it 'should update evolution_api status' do
          stub_request(:delete, /delete/)
          .to_return(body: delete_instance_response.to_json, status: 200, headers: {'Content-Type' => 'application/json'})
          post_webhook(deleted_connection_event)
          expect_success
          expect(evolution_api_connected.reload.disconnected?).to be_truthy
        end
      end
    end
    describe 'when evolution_api is disconnected' do
      let!(:evolution_api) { create(:apps_evolution_api, account: account) }
      context 'when is qrcode_update event' do
        it 'evolution_api should not be changed' do
          post_webhook(qrcode_updated_webhook_event)
          expect_success
          expect(evolution_api.reload.changed?).to be_falsey
        end
      end
      context 'when is deleted_connection event' do
        it 'evolution_api should not be changed' do
          post_webhook(deleted_connection_event)
          expect_success
          expect(evolution_api.reload.changed?).to be_falsey
        end
      end
    end
  end
end
