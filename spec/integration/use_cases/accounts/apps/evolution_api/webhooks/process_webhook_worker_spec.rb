require 'rails_helper'
require 'webmock/rspec'
require 'sidekiq/testing'

RSpec.describe Accounts::Apps::EvolutionApis::Webhooks::ProcessWebhookWorker, type: :request do
  describe '.perform' do
    let(:account) { create(:account) }
    let(:evolution_api) { create(:apps_evolution_api, account: account) }
    let(:qrcode_updated_webhook_event) do
      File.read('spec/integration/use_cases/accounts/apps/evolution_api/webhooks/events/qrcode_updated_event.json')
    end
    let(:created_connection_event) do
      File.read('spec/integration/use_cases/accounts/apps/evolution_api/webhooks/events/created_connection_event.json')
    end
    let(:evolution_api_additional_attributes) { evolution_api.reload.additional_attributes }

    describe 'when is qrcode_update event' do
      context 'success' do
        it 'should update additional_attributes' do
          allow(Time).to receive(:current).and_return(Time.new(2024, 1, 27, 0, 0, 0))
          evolution_api
          Sidekiq::Testing.inline! do
            described_class.perform_async(qrcode_updated_webhook_event)
          end
          expect(evolution_api.reload.additional_attributes).to eq({ 'qrcode' => 'qrcode',
                                                                     'expiration_date' => (Time.new(2024, 1, 27, 0, 0,
                                                                                                    0) + 50.seconds).to_s })
        end
      end
    end
    describe 'when is created_connection event' do
      context 'success' do
        it 'should update evolution_api status and phone' do
          evolution_api.update(additional_attributes: {qrcode: 'qrcode', expiration_date: Time.current})
          Sidekiq::Testing.inline! do
            described_class.perform_async(created_connection_event)
          end
          expect(evolution_api.reload.connection_status).to eq('active')
          expect(evolution_api.reload.phone).to be_truthy
          expect(evolution_api.reload.additional_attributes).not_to include('qrcode', 'expired_date')

        end
      end
    end
  end
end
