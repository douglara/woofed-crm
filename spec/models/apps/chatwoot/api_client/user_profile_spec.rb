# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Apps::Chatwoot::ApiClient, type: :model do
  let(:apps_chatwoot) { build(:apps_chatwoots, chatwoot_endpoint_url: 'https://chatwoot.com') }
  subject { described_class.new(apps_chatwoot) }
  let(:request_headers) { { 'Content-Type' => 'application/json' } }

  describe '#user_profile' do
    let(:profile_response) do
      File.read('spec/fixtures/models/apps/chatwoot/api_client/profile_request.json')
    end
    context 'return user profile' do
      before do
        stub_request(:get, 'https://chatwoot.com/api/v1/profile')
          .to_return(status: 200, body: profile_response, headers: request_headers)
      end

      it do
        expect(subject.user_profile[:ok]['email']).to eq('tim@email.com.br')
      end
    end

    context 'when request fails' do
      before do
        stub_request(:get, 'https://chatwoot.com/api/v1/profile')
          .to_return(status: 404, body: '', headers: request_headers)
      end

      it 'return error' do
        expect(subject.user_profile[:error]).to eq('Failed to fetch user profile')
      end
    end
  end
end
