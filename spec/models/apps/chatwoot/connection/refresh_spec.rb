# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Apps::Chatwoot::Connection::Refresh, type: :model do
  let!(:apps_chatwoot) { create(:apps_chatwoots, :skip_validate, chatwoot_endpoint_url: 'https://chatwoot.com') }
  subject { described_class.new(apps_chatwoot) }

  describe '#call' do
    context 'refresh inboxes' do
      before do
        allow(apps_chatwoot).to receive(:valid_token?).and_return(true)
        allow(Accounts::Apps::Chatwoots::GetInboxes).to receive(:call)
          .with(apps_chatwoot)
          .and_return(
            { ok: [
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
                  ]})
      end

      it 'returns parsed response with :ok key' do
        expect(subject.call).to be_truthy
      end
    end

    context 'when the token is invalid' do
      before do
        allow(apps_chatwoot).to receive(:valid_token?).and_return(false)
      end

      it 'updates the status to inactive' do
        expect { subject.call }.to change { apps_chatwoot.status }.from('active').to('inactive')
      end
    end
  end
end
