# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Apps::Chatwoot::Connection::Refresh, type: :model do
  let!(:apps_chatwoot) { create(:apps_chatwoots, :skip_validate, chatwoot_endpoint_url: 'https://chatwoot.com') }
  let(:inboxes_result) do
    [
      {
        "id": 1,
        "name": 'Inbox 2',
        "channel_type": 'Channel::Api'
      },
      {
        "id": 2,
        "name": 'Inbox 2',
        "channel_type": 'Channel::Api'
      }
    ].to_json
  end

  subject { described_class.new(apps_chatwoot) }

  describe '#call' do
    context 'when the token is valid' do
       before do
        allow(apps_chatwoot).to receive(:invalid_token?).and_return(false)
      end

      context 'refresh inboxes' do
        before do
          allow(apps_chatwoot).to receive(:invalid_token?).and_return(false)
          allow(Accounts::Apps::Chatwoots::GetInboxes).to receive(:call)
            .with(apps_chatwoot)
            .and_return(
              { ok: inboxes_result }
            )
        end

        it 'returns parsed response with :ok key' do
          expect(subject.call).to be_truthy
          expect(apps_chatwoot.inboxes).to eq(inboxes_result)
        end
      end

      context 'not refresh inboxes' do
        before do
          allow(Accounts::Apps::Chatwoots::GetInboxes).to receive(:call)
            .with(apps_chatwoot)
            .and_return(
              { error: 'inbox error' }
            )
        end

        it 'when chatwoot get inboxes returns error' do
          expect(subject.call).to be_truthy
          expect(apps_chatwoot.inboxes).to be_empty
        end
      end
    end

    context 'when the token is invalid' do
      before do
        allow(apps_chatwoot).to receive(:invalid_token?).and_return(true)
      end

      it 'updates the status to inactive' do
        expect { subject.call }.to change { apps_chatwoot.status }.from('active').to('inactive')
      end
    end
  end
end
