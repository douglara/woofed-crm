# == Schema Information
#
# Table name: apps_salesforces
#
#  id               :bigint           not null, primary key
#  access_token     :text
#  api_version      :string           default("v64.0"), not null
#  client_secret    :text
#  environment      :string           default("production"), not null
#  instance_url     :string           default(""), not null
#  name             :string           default(""), not null
#  refresh_token    :text
#  settings         :jsonb            not null
#  status           :string           default("inactive"), not null
#  token_expires_at :datetime
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  client_id        :string           default(""), not null
#  organization_id  :string           default(""), not null
#
# spec/models/apps/salesforce_spec.rb
require 'rails_helper'

RSpec.describe Apps::Salesforce do
  describe 'validations' do
    context 'validates client_id' do
      context 'valid' do
        it do
          connection = build(:apps_salesforces, client_id: 'consumer-key')

          expect(connection).to be_valid
        end
      end
      context 'invalid' do
        it 'when client_id is blank' do
          connection = build(:apps_salesforces, client_id: '')

          expect(connection).to be_invalid
          expect(connection.errors[:client_id]).to include("can't be blank")
        end
      end
    end
    context 'validates client_secret' do
      context 'valid' do
        it do
          connection = build(:apps_salesforces, client_secret: 'consumer-secret')

          expect(connection).to be_valid
        end
      end
      context 'invalid' do
        it 'when client_secret is blank' do
          connection = build(:apps_salesforces, client_secret: nil)

          expect(connection).to be_invalid
          expect(connection.errors[:client_secret]).to include("can't be blank")
        end
      end
    end
    context 'validates the single connection per install' do
      context 'valid' do
        it 'when it is the first connection' do
          connection = build(:apps_salesforces)

          expect(connection).to be_valid
        end
        it 'when the already connected org is updated' do
          connection = create(:apps_salesforces, :connected)

          expect(connection.update(name: 'Salesforce production')).to be(true)
        end
      end
      context 'invalid' do
        it 'when another connection already exists' do
          create(:apps_salesforces)
          connection = build(:apps_salesforces)

          expect(connection).to be_invalid
          expect(connection.errors[:base]).to include(
            I18n.t('activerecord.errors.messages.salesforce_connection_already_exists')
          )
        end
      end
    end
  end

  describe 'callbacks' do
    describe 'before_destroy' do
      describe '#revoke_refresh_token' do
        let(:revoke_url) { 'https://woofed-dev-ed.my.salesforce.com/services/oauth2/revoke' }

        it 'revokes the refresh token on the salesforce side' do
          stub_request(:post, revoke_url).to_return(status: 200)

          create(:apps_salesforces, :connected).destroy

          expect(a_request(:post, revoke_url).with(body: 'token=refresh-token')).to have_been_made
          expect(described_class.count).to eq(0)
        end

        it 'skips the revocation when no refresh token was ever stored' do
          create(:apps_salesforces).destroy

          expect(described_class.count).to eq(0)
        end

        it 'destroys the connection even when salesforce is unreachable' do
          stub_request(:post, revoke_url).to_timeout

          expect { create(:apps_salesforces, :connected).destroy }.not_to raise_error
          expect(described_class.count).to eq(0)
        end
      end
    end
  end

  describe 'credential storage' do
    it 'keeps the oauth credentials out of the database in plaintext' do
      connection = create(:apps_salesforces, :connected)
      stored = described_class.connection.select_one(
        described_class.sanitize_sql(
          ['SELECT client_secret, access_token, refresh_token FROM apps_salesforces WHERE id = ?', connection.id]
        )
      )

      expect(stored.values.join).not_to include('consumer-secret', 'access-token', 'refresh-token')
      expect(connection.reload).to have_attributes(
        client_secret: 'consumer-secret',
        access_token: 'access-token',
        refresh_token: 'refresh-token'
      )
    end
  end

  describe '#login_url' do
    it 'authenticates production orgs against login and sandboxes against test' do
      expect(build(:apps_salesforces).login_url).to eq('https://login.salesforce.com')
      expect(build(:apps_salesforces, :sandbox).login_url).to eq('https://test.salesforce.com')
    end
  end

  describe '#api_url' do
    it 'builds the versioned api path on the instance returned by salesforce' do
      connection = build(:apps_salesforces, :connected)

      expect(connection.api_url).to eq('https://woofed-dev-ed.my.salesforce.com/services/data/v64.0')
    end
  end

  describe '#connected?' do
    it 'is connected once an instance url and a refresh token are stored' do
      expect(build(:apps_salesforces, :connected)).to be_connected
      expect(build(:apps_salesforces, :connected, refresh_token: nil)).not_to be_connected
      expect(build(:apps_salesforces, :connected, instance_url: '')).not_to be_connected
    end
  end

  describe '#token_expired?' do
    it 'treats an unknown expiry as not expired, since salesforce omits expires_in' do
      expect(build(:apps_salesforces, token_expires_at: nil)).not_to be_token_expired
    end

    it 'expires inside the refresh margin, so no request is sent with a dying token' do
      expect(build(:apps_salesforces, :token_expired)).to be_token_expired
      expect(build(:apps_salesforces, token_expires_at: 3.minutes.from_now)).to be_token_expired
      expect(build(:apps_salesforces, token_expires_at: 30.minutes.from_now)).not_to be_token_expired
    end
  end
end
