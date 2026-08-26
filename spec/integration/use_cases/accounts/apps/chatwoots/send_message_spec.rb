require 'rails_helper'

RSpec.describe Accounts::Apps::Chatwoots::SendMessage, type: :request do
  describe 'success' do
    let(:account) { create(:account) }
    let(:chatwoot) { create(:apps_chatwoots, :skip_validate) }

    context 'when event has no file' do
      let(:event) { create(:event) }
      let(:response) { File.read('spec/integration/use_cases/accounts/apps/chatwoots/send_message.json') }

      it do
        stub_request(:post, /messages/)
        .to_return(body: response, status: 200, headers: { 'Content-Type' => 'application/json' })

        result = Accounts::Apps::Chatwoots::SendMessage.call(chatwoot, 10, event)
        expect(result[:ok]['id']).to eq(227)
      end
    end

    context 'when event has file' do
      let(:file_response) { File.read('spec/integration/use_cases/accounts/apps/chatwoots/send_message_with_attachment.json') }
      let(:event_with_file) { create(:event, :with_file) }

      it 'with content' do
        stub_request(:any, /patrick/).
         to_return(body: File.new('spec/fixtures/files/patrick.png'), status: 200)
        stub_request(:post, /messages/)
          .to_return(body: file_response, status: 200, headers: { 'Content-Type' => 'application/json' })

        expect(Accounts::Apps::Chatwoots::SendMessage.call(chatwoot, 10, event_with_file)[:ok]['id']).to eq(9583)
      end

      context 'when event has no content' do
        let(:event_with_file) { create(:event, :with_file, content: '') }
        it do
          stub_request(:any, /patrick/).
           to_return(body: File.new('spec/fixtures/files/patrick.png'), status: 200)
          stub_request(:post, /messages/)
            .to_return(body: file_response, status: 200, headers: { 'Content-Type' => 'application/json' })

          expect(Accounts::Apps::Chatwoots::SendMessage.call(chatwoot, 10, event_with_file)[:ok]['id']).to eq(9583)
        end
      end
    end
  end

  describe '.build_body' do
    let(:account) { create(:account) }
    let(:inbox) { JSON.parse(File.read('spec/integration/use_cases/accounts/apps/chatwoots/inbox_detail.json')) }
    let(:chatwoot) { create(:apps_chatwoots, :skip_validate, account:, inboxes: [inbox]) }
    let(:contact) { create(:contact, account:) }

    it 'returns a plain content hash for a free-text message' do
      event = build(:event, kind: 'chatwoot_message', app: chatwoot, contact:, deal: nil, content: 'Hi Lorena')
      expect(described_class.build_body(event)).to eq('content' => 'Hi Lorena')
    end

    it 'includes template_params and resolved content for a template message' do
      event = build(:event, kind: 'chatwoot_message', app: chatwoot, contact:, deal: nil,
                            additional_attributes: { 'chatwoot_inbox_id' => 101,
                                                     'chatwoot_template_name' => 'lembrete_aula',
                                                     'template_body_params' => { '1' => 'Paula', '2' => '14:00' } })
      body = described_class.build_body(event)
      expect(body['content']).to eq('Oi Paula! Sua aula experimental e hoje as 14:00!')
      expect(body['template_params']['name']).to eq('lembrete_aula')
      expect(body['template_params']['processed_params']).to eq('body' => { '1' => 'Paula', '2' => '14:00' })
    end
  end
end
