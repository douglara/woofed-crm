# == Schema Information
#
# Table name: apps_evolution_apis
#
#  id           :bigint           not null, primary key
#  active       :boolean
#  endpoint_url :string
#  name         :string
#  phone        :string
#  status       :string
#  token        :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :bigint           not null
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

  def request_headers
    {'apiKey': "#{ENV['EVOLUTION_API_ENDPOINT_TOKEN']}", 'Content-Type': 'application/json'}
  end
end
