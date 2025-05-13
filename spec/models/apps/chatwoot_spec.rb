require 'rails_helper'

RSpec.describe Apps::Chatwoot do

  describe 'normalizes' do
    context 'normalize chatwoot_endpoint_url' do
      it 'removes multiple trailing slashes on assignment' do
        chatwoot = build(:apps_chatwoots, chatwoot_endpoint_url: 'https://chatwoot.com//////')
        expect(chatwoot.chatwoot_endpoint_url).to eq('https://chatwoot.com')
      end

      it 'preserves URL without trailing slashes' do
        chatwoot = build(:apps_chatwoots, chatwoot_endpoint_url: 'https://chatwoot.com')
        expect(chatwoot.chatwoot_endpoint_url).to eq('https://chatwoot.com')
      end

      it 'handles nil value' do
        chatwoot = build(:apps_chatwoots, chatwoot_endpoint_url: nil)
        expect(chatwoot.chatwoot_endpoint_url).to be_nil
      end

      it 'removes trailing slashes when saving' do
        chatwoot = create(:apps_chatwoots, :skip_validate, chatwoot_endpoint_url: 'https://chatwoot.com//////')
        expect(chatwoot.reload.chatwoot_endpoint_url).to eq('https://chatwoot.com')
      end

      it 'handles query strings correctly' do
        chatwoot = build(:apps_chatwoots, chatwoot_endpoint_url: 'https://chatwoot.com?param=1////')
        expect(chatwoot.chatwoot_endpoint_url).to eq('https://chatwoot.com?param=1')
      end
    end
  end
end
