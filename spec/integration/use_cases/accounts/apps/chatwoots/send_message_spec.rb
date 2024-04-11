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
end
