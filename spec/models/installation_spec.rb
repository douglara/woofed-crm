# frozen_string_literal: true

# == Schema Information
#
# Table name: installations
#
#  id         :string           not null, primary key
#  key1       :string           default(""), not null
#  key2       :string           default(""), not null
#  status     :integer          default("in_progress"), not null
#  token      :string           default(""), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint
#
# Indexes
#
#  index_installations_on_user_id  (user_id)
#
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
  describe '#installation_url' do
    it do
      expect(Installation.installation_url).to eq('https://store.woofedcrm.com/installations/new?installation_params={"url":"http://www.example.com","kind":"self_hosted"}')
    end

    context 'when FRONTEND_URL is set' do
      before do
        allow(ENV).to receive(:fetch).and_call_original
        allow(ENV).to receive(:fetch).with('FRONTEND_URL', 'http://localhost:3001').and_return('https://app.woofedcrm.com')
      end

      it do
        expect(Installation.installation_url).to eq('https://store.woofedcrm.com/installations/new?installation_params={"url":"https://app.woofedcrm.com","kind":"self_hosted"}')
      end
    end

    context 'when FRONTEND_URL is not set' do
      before do
        allow(ENV).to receive(:fetch).and_call_original
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
      let!(:installation) { create(:installation, status: 'completed') }

      it do
        expect(Installation.installation_flow?).to eq(false)
      end
    end
  end
end
