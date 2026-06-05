# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  avatar_url             :string           default(""), not null
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :string
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  failed_attempts        :integer          default(0)
#  full_name              :string           default(""), not null
#  job_description        :string           default("other"), not null
#  language               :string           default("en"), not null
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :string
#  locked_at              :datetime
#  notifications          :jsonb            not null
#  phone                  :string
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  sign_in_count          :integer          default(0)
#  theme_preference       :string           default("system"), not null
#  unlock_token           :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_unlock_token          (unlock_token) UNIQUE
#
require 'rails_helper'

RSpec.describe User do
  describe 'callbacks' do
    describe 'after_create' do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('FRONTEND_URL').and_return('http://test.woofedcrm.local')
      end

      context 'when FRONTEND_URL is configured' do
        it 'mints a Woofed AI Doorkeeper access token bound to the user' do
          expect do
            create(:user)
          end.to change(Doorkeeper::AccessToken, :count).by(1)

          user = User.last
          token = Doorkeeper::AccessToken
                  .joins(:application)
                  .where(oauth_applications: { name: 'Woofed AI' })
                  .find_by(resource_owner_id: user.id)

          expect(token).to have_attributes(
            scopes: a_string_including('mcp'),
            resource: 'http://test.woofedcrm.local/mcp',
            revoked_at: nil,
            expires_in: nil
          )
        end

        it 'reuses the existing Woofed AI Doorkeeper application across users' do
          expect do
            create(:user)
            create(:user)
          end.to change(Doorkeeper::Application, :count).by(1)

          expect(Doorkeeper::Application.where(name: 'Woofed AI').count).to eq(1)
          expect(Doorkeeper::AccessToken.joins(:application)
                  .where(oauth_applications: { name: 'Woofed AI' }).count).to eq(2)
        end
      end

      context 'when FRONTEND_URL is blank' do
        before do
          allow(ENV).to receive(:[]).with('FRONTEND_URL').and_return(nil)
        end

        it 'rolls back the user creation and surfaces the configuration error' do
          expect do
            expect { create(:user) }.to raise_error(/FRONTEND_URL is required/)
          end.not_to change(User, :count)
        end
      end
    end
  end
end
