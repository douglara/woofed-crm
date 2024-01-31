require 'rails_helper'
require 'webmock/rspec'
require 'sidekiq/testing'

RSpec.describe Apps::EvolutionApisController, type: :request do
  let(:account) { create(:account) }
  let!(:evolution_api) { create(:apps_evolution_api, account: account) }
  let(:evolution_api_connected) { create(:apps_evolution_api, :connected, account: account) }
  let(:qrcode_updated_webhook_event) { load_webhook_event('qrcode_updated_event.json') }
  let(:created_connection_event) { load_webhook_event('created_connection_event.json') }
  let(:deleted_connection_event) { load_webhook_event('deleted_connection_event.json') }
  let(:evolution_api_qrcode_info) { evolution_api.reload.qrcode_info }

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
    describe 'when is qrcode_update event' do
      context 'success' do
        it 'should update qrcode_info' do
          allow(Time).to receive(:current).and_return(Time.new(2024, 1, 27, 0, 0, 0))
          post_webhook(qrcode_updated_webhook_event)
          expect_success
          expect(evolution_api.reload.qrcode).to eq('qrcode')
        end
      end
    end
    describe 'when is created_connection event' do
      context 'success' do
        it 'should update evolution_api status and phone' do
          evolution_api.update(qrcode: 'qrcode')
          post_webhook(created_connection_event)
          expect_success
          expect(evolution_api.reload.connection_status).to eq('active')
          expect(evolution_api.phone).to be_present
          expect(evolution_api.qrcode).not_to be_present
        end
      end
    end
    describe 'when is deleted_connection event' do
      before do
        stub_request(:delete, /logout/)
        .to_return(body: {}.to_json, status: 200, headers: {'Content-Type' => 'application/json'})
      end
      context 'success' do
        it 'should update evolution_api status and phone' do
          evolution_api_connected
          post_webhook(deleted_connection_event)
          expect_success
          expect(evolution_api.reload.connection_status).to eq('inactive')
        end
      end
    end
  end
end
