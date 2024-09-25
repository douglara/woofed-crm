# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Installation do
  skip '#complete_installation!' do
    let!(:user) { create(:user) }
    let!(:installation) { create(:installation) }
    context 'should complete installation' do
      it do
        expect(installation.complete_installation!).to eq(true)
        expect(installation.status).to eq('completed')
        assert_raise ActionController::UrlGenerationError do
          installation_step_1_path
        end
      end
    end
  end

  describe '#register_completed_install' do
    let!(:account) { create(:account) }
    let!(:installation) { create(:installation) }
    let!(:user) { create(:user) }
    context 'when valid registration' do
      before do
        stub_request(:post, 'https://store.woofedcrm.com/installations/complete')
          .to_return(body: { message: 'Installation completed' }.to_json, status: 200, headers: { 'Content-Type' => 'application/json' })
      end

      it do
        expect(installation.register_completed_install).to eq(true)
      end
    end

    context 'when invalid registration' do
      context 'invalid token' do
        before do
          stub_request(:post, 'https://store.woofedcrm.com/installations/complete')
            .to_return(body: { errors: 'Unauthorized' }.to_json, status: 401, headers: { 'Content-Type' => 'application/json' })
        end

        it do
          expect(installation.register_completed_install).to eq(false)
        end

        context 'invalid params' do
          before do
            stub_request(:post, 'https://store.woofedcrm.com/installations/complete')
              .to_return(body: { errors: 'Invalid params' }.to_json, status: 422, headers: { 'Content-Type' => 'application/json' })
          end

          it do
            expect(installation.register_completed_install).to eq(false)
          end
        end
      end
    end
  end
end
