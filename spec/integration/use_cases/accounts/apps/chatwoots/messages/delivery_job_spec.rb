require 'rails_helper'

RSpec.describe Accounts::Apps::Chatwoots::Messages::DeliveryJob, type: :request do
  describe 'success' do
    let(:account) { create(:account) }
    let(:chatwoot) { create(:apps_chatwoots, :skip_validate) }
    let(:contact) { create(:contact, account:, additional_attributes: { chatwoot_id: 2 }) }
    let(:event) do
      create(:event, app: chatwoot, account:, contact:, content: 'Hi Lorena', from_me: true, scheduled_at: Time.now,
                     kind: 'chatwoot_message', additional_attributes: { chatwoot_inbox_id: 2 })
    end

    let(:conversation_response) do
      File.read('spec/integration/use_cases/accounts/apps/chatwoots/get_conversations.json')
    end
    let(:message_response) { File.read('spec/integration/use_cases/accounts/apps/chatwoots/send_message.json') }

    it do
      stub_request(:get, /conversations/)
        .to_return(body: conversation_response, status: 200, headers: { 'Content-Type' => 'application/json' })
      stub_request(:post, /messages/)
        .to_return(body: message_response, status: 200, headers: { 'Content-Type' => 'application/json' })

      result = described_class.perform_now(event.id)

      expect(result[:ok].additional_attributes['chatwoot_id']).to eq(227)
    end

    context 'when the event is a whatsapp template' do
      let(:inbox) { JSON.parse(File.read('spec/integration/use_cases/accounts/apps/chatwoots/inbox_detail.json')) }
      let(:chatwoot) { create(:apps_chatwoots, :skip_validate, inboxes: [inbox]) }
      let(:event) do
        create(:event, app: chatwoot, account:, contact:, from_me: true, scheduled_at: Time.now,
                       kind: 'chatwoot_message',
                       additional_attributes: { 'chatwoot_inbox_id' => 101,
                                                'chatwoot_template_name' => 'lembrete_aula',
                                                'template_body_params' => { '1' => 'Paula', '2' => '14:00' } })
      end

      let(:create_conversation_response) do
        File.read('spec/integration/use_cases/accounts/apps/chatwoots/create_conversation.json')
      end

      it 'posts the resolved content and template params to chatwoot' do
        stub_request(:get, /conversations/)
          .to_return(body: { payload: [] }.to_json, status: 200, headers: { 'Content-Type' => 'application/json' })
        stub_request(:post, /conversations/)
          .to_return(body: create_conversation_response, status: 200, headers: { 'Content-Type' => 'application/json' })
        stub_request(:post, /messages/)
          .to_return(body: message_response, status: 200, headers: { 'Content-Type' => 'application/json' })

        described_class.perform_now(event.id)

        expect(a_request(:post, /messages/).with do |req|
          body = JSON.parse(req.body)
          body['content'] == 'Oi Paula! Sua aula experimental e hoje as 14:00!' &&
            body['template_params'] == {
              'name' => 'lembrete_aula', 'category' => 'UTILITY', 'language' => 'pt_BR',
              'processed_params' => { 'body' => { '1' => 'Paula', '2' => '14:00' } }
            }
        end).to have_been_made
      end
    end
  end
end
