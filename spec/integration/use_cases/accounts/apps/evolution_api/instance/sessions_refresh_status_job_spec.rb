# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Accounts::Apps::EvolutionApis::Instance::SessionsRefreshStatusJob, type: :request do
  describe '.call' do
    let(:account) { create(:account) }
    let!(:evolution_api_active) { create(:apps_evolution_api, :connected, account: account) }
    let!(:evolution_api_inactive) { create(:apps_evolution_api, :connected, account: account) }
    let(:delete_instance_response) do
      File.read('spec/integration/use_cases/accounts/apps/evolution_api/instance/delete_response.json')
    end

    it 'refresh instances status' do
      stub_request(:get, /#{evolution_api_active.instance}/)
        .to_return(body: '{"instance":{"instanceName":"dd7de5acfca04cd65459","state":"open"}}', status: 200, headers: { 'Content-Type' => 'application/json' })
      stub_request(:get, /#{evolution_api_inactive.instance}/)
        .to_return(body: '{"status":404,"error":"Not Found","response":{"message":["The \"9244ecdbda2c251315e6\" instance does not exist"]}}', status: 404, headers: { 'Content-Type' => 'application/json' })
      stub_request(:delete, /delete/)
        .to_return(body: delete_instance_response.to_json, status: 200, headers: { 'Content-Type' => 'application/json' })
      described_class.perform_now
      expect(evolution_api_active.reload.connection_status).to eq('connected')
      expect(evolution_api_inactive.reload.connection_status).to eq('disconnected')
    end
  end
end
