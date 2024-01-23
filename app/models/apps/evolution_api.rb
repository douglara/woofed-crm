# == Schema Information
#
# Table name: apps_evolution_apis
#
#  id                    :bigint           not null, primary key
#  active                :boolean
#  additional_attributes :jsonb
#  endpoint_url          :string
#  name                  :string
#  phone                 :string
#  status                :string
#  token                 :string
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

  belongs_to :account

  scope :actives, -> { where(active: true) }

  enum status: {
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
