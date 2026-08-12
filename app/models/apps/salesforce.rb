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
class Apps::Salesforce < ApplicationRecord
  include Apps::Salesforce::Urls, Apps::Salesforce::TokenManagement

  enum status: {
    'inactive': 'inactive',
    'active': 'active',
    'syncing': 'syncing',
    'error': 'error'
  }

  enum environment: {
    'production': 'production',
    'sandbox': 'sandbox'
  }

  validates :client_id, presence: true
  validates :client_secret, presence: true
  validate :only_one_connection, on: :create

  def connected?
    instance_url.present? && refresh_token.present?
  end

  def api_client
    Apps::Salesforce::Api::Client.new(self)
  end

  private

  # A Woofed install talks to a single Salesforce org. The rule lives here and not
  # in the schema so that supporting several connections later is a UI change plus
  # removing this validation, with no migration.
  def only_one_connection
    return unless self.class.exists?

    errors.add(:base, I18n.t('activerecord.errors.messages.salesforce_connection_already_exists'))
  end
end
