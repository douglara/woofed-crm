# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Accounts::Apps::EvolutionApis::Message::DeliveryJob, type: :request do
  describe 'success' do
    let(:account) { create(:account) }
    let(:evolution_api_connected) { create(:apps_evolution_api, :connected, account: account) }
    let(:send_text_response) do
      File.read('spec/integration/use_cases/accounts/apps/evolution_api/message/send_text_response.json')
    end
    let(:send_image_response) do
      File.read('spec/integration/use_cases/accounts/apps/evolution_api/message/send_image_response.json')
    end
    let(:contact) do
      create(:contact, account: account, phone: '', additional_attributes: { group_id: '120363103459410972@g.us' })
    end

    context 'should send message' do
      context 'group' do
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
      context 'when is message with attachment' do
        let(:event) do
          create(:event, :with_file, app: evolution_api_connected, content: 'message with image', account: account, from_me: true,
                                     scheduled_at: Time.now, kind: 'evolution_api_message')
        end
        it do
          stub_request(:post, /sendMedia/)
            .to_return(body: send_image_response, status: 201, headers: { 'Content-Type' => 'application/json' })

          Accounts::Apps::EvolutionApis::Message::DeliveryJob.perform_now(event.id)
          expect(event.reload.done).to eq(true)
        end
      end
    end
  end
end
