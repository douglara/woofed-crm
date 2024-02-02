# == Schema Information
#
# Table name: apps_evolution_apis
#
#  id                    :bigint           not null, primary key
#  active                :boolean          default(TRUE), not null
#  additional_attributes :jsonb
#  connection_status     :string           default("disconnected"), not null
#  endpoint_url          :string           default(""), not null
#  instance              :string           default(""), not null
#  name                  :string           default(""), not null
#  phone                 :string           default(""), not null
#  qrcode                :string           default(""), not null
#  token                 :string           default(""), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  account_id            :bigint           not null
#
# Indexes
#
#  index_apps_evolution_apis_on_account_id  (account_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class Apps::EvolutionApi < ApplicationRecord
  include Applicable
  include Rails.application.routes.url_helpers

  validates :endpoint_url, presence: true
  validates :token, presence: true
  validates :name, presence: true
  validates :instance, presence: true
  # validate :validate_evolution_api, on: :create
  after_create :create_instance
  after_commit :broadcast_update_qrcode, if: -> { saved_change_to_qrcode? }
  scope :actives, -> { where(active: true) }

  enum connection_status: {
    'disconnected': 'disconnected',
    'connected': 'connected',
    'sync': 'sync',
    'connecting': 'connecting'
  }

  after_update_commit do
    if saved_change_to_connection_status?(from: 'inactive', to: 'active')
        broadcast_replace_later_to "qrcode_#{self.id}", target: self, partial: '/components/redirect_page',
      locals: { path: Rails.application.routes.url_helpers.account_apps_evolution_apis_path(self.account) }
    end
    broadcast_replace_later_to "evolution_apis_#{account_id}", target: self, partial: '/accounts/apps/evolution_apis/evolution_api',
    locals: { evolution_api: self }
  end

  after_create_commit do
    broadcast_append_later_to "evolution_apis_#{account_id}", target: 'evolution_apis', partial: '/accounts/apps/evolution_apis/evolution_api',
    locals: { evolution_api: self }
  end

  after_destroy_commit do
    broadcast_remove_to "evolution_apis_#{account_id}", target: self
  end

  def broadcast_update_qrcode
    broadcast_replace_later_to "qrcode_#{self.id}", target: self, partial: 'accounts/apps/evolution_apis/qrcode',
                                                 locals: { evolution_api: self }
  end

  def request_instance_headers
    { 'apiKey': token.to_s, 'Content-Type': 'application/json' }
  end

  def woofedcrm_webhooks_url
    "#{ENV['FRONTEND_URL']}/apps/evolution_apis/webhooks"
  end

  # def validate_evolution_api
  #   result = Accounts::Apps::EvolutionApis::Instance::Create.call(self)
  #   if result.key?(:error)
  #     errors.add(:error, "#{result[:error]['response']['message']}")
  #   end
  # end
  def create_instance
    Accounts::Apps::EvolutionApis::Instance::Create.call(self)
  end

  def generate_token(field)
    loop do
      security_token = SecureRandom.hex(10)
      break security_token unless Apps::EvolutionApi.where(field => security_token).exists?
    end
  end
end
