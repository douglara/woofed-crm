# == Schema Information
#
# Table name: apps_evolution_apis
#
#  id                    :bigint           not null, primary key
#  active                :boolean          default(TRUE), not null
#  additional_attributes :jsonb
#  connection_status     :string           default("inactive"), not null
#  endpoint_url          :string           default(""), not null
#  instance              :string           default(""), not null
#  name                  :string           default(""), not null
#  phone                 :string           default(""), not null
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

  validates :endpoint_url, presence: true
  validates :token, presence: true
  validates :name, presence: true
  validates :instance, presence: true
  # validate :validate_evolution_api, on: :create
  after_create :create_instance
  after_commit :broadcast_update_qrcode, if: -> { saved_change_to_name? }
  scope :actives, -> { where(active: true) }

  enum connection_status: {
    'inactive': 'inactive',
    'active': 'active',
    'sync': 'sync',
    'pair': 'pair'
  }

  after_update_commit do
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
    broadcast_replace_later_to "qrcode_#{account.id}", target: self, partial: 'accounts/apps/evolution_apis/qrcode',
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
