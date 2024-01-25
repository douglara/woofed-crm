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
  scope :actives, -> { where(active: true) }

  enum connection_status: {
    'inactive': 'inactive',
    'active': 'active',
    'sync': 'sync',
    'pair': 'pair',
  }

  def request_instance_headers
    {'apiKey': "#{key}", 'Content-Type': 'application/json'}
  end

  def generate_token(field)
    loop do
      security_token = SecureRandom.hex(10)
      break security_token unless Apps::EvolutionApi.where(field => security_token).exists?
    end
  end
end
