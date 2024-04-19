# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Accounts::Apps::EvolutionApis::Message::DeliveryJob, type: :request do
  describe 'success' do
    let(:account) { create(:account) }
    let(:evolution_api_connected) { create(:apps_evolution_api, :connected, account: account) }
    let(:send_text_response) do
      File.read('spec/integration/use_cases/accounts/apps/evolution_api/message/send_text_response.json')
    end

    context 'should send message' do
      context 'group' do
        let(:contact) do
          create(:contact, account: account, phone: '', additional_attributes: { group_id: '120363103459410972@g.us' })
        end
        let(:event) do
          create(:event, app: evolution_api_connected, account: account, content: 'Hi Lorena', from_me: true,
                         scheduled_at: Time.now, kind: 'evolution_api_message')
        end

        it do
          stub_request(:post, /sendText/)
            .to_return(body: send_text_response, status: 201, headers: { 'Content-Type' => 'application/json' })

          Accounts::Apps::EvolutionApis::Message::DeliveryJob.perform_now(event.id)
          expect(event.reload.done).to eq(true)
        end
      end
    end
  end
end
