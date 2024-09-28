# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Installation do
  before(:each) do
    Installation.delete_all
    load "#{Rails.root}/app/controllers/application_controller.rb"
    Rails.application.reload_routes!
  end

  after(:each) do
    load "#{Rails.root}/app/controllers/application_controller.rb"
    Rails.application.reload_routes!
  end

  context '#complete_installation!' do
    let!(:user) { create(:user) }

    context 'when there is in_progress installation registered' do
      let!(:installation) { create(:installation, status: 'in_progress') }

      context 'when there is an account registered' do
        let!(:account) { create(:account) }
        before do
          stub_request(:post, 'https://store.woofedcrm.com/installations/complete')
            .to_return(body: { message: 'Installation completed' }.to_json, status: 200, headers: { 'Content-Type' => 'application/json' })
        end
        it 'should return true and update installation status to completed' do
          expect(installation.complete_installation!).to eq(true)
          expect(installation.status).to eq('completed')
        end
      end
      context 'when there is no account registered' do
        it 'should return nil and not update complete installation' do
          expect(installation.complete_installation!).to eq(nil)
          expect(installation.status).to eq('in_progress')
        end
      end
    end

    context 'when there is completed installation registered' do
      let!(:installation) { create(:installation, status: 'completed') }
      let!(:account) { create(:account) }
      it 'should return nil and not update complete installation' do
        expect(installation.complete_installation!).to eq(nil)
        expect(installation.status).to eq('completed')
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
