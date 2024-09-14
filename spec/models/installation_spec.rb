# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Installation do
  describe '#installation_url' do
    it do
      expect(Installation.installation_url).to eq('https://store.woofedcrm.com/installations/new?installation_params={"url":"http://www.example.com","kind":"self_hosted"}')
    end

    context 'when FRONTEND_URL is set' do
      before do
        allow(ENV).to receive(:fetch).with('FRONTEND_URL', 'http://localhost:3001').and_return('https://app.woofedcrm.com')
      end

      it do
        expect(Installation.installation_url).to eq('https://store.woofedcrm.com/installations/new?installation_params={"url":"https://app.woofedcrm.com","kind":"self_hosted"}')
      end
    end

    context 'when FRONTEND_URL is not set' do
      before do
        allow(ENV).to receive(:fetch).with('FRONTEND_URL', 'http://localhost:3001').and_return('http://localhost:3001')
      end

      it do
        expect(Installation.installation_url).to eq('https://store.woofedcrm.com/installations/new?installation_params={"url":"http://localhost:3001","kind":"self_hosted"}')
      end
    end
  end
  describe '#installation_flow?' do
    context 'when is new installation' do
      it do
        expect(Installation.installation_flow?).to eq(true)
      end
    end

    context 'when is inatalled' do
      let!(:user) { create(:user) }

      it do
        expect(Installation.installation_flow?).to eq(false)
      end
    end
  end
end
