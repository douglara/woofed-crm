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
#
class Apps::EvolutionApi < ApplicationRecord
  include Rails.application.routes.url_helpers
  include EvolutionApi::Broadcastable

  validates :endpoint_url, presence: true
  validates :token, presence: true
  validates :name, presence: true
  validates :instance, presence: true
  scope :actives, -> { where(active: true) }

  enum connection_status: {
    'disconnected': 'disconnected',
    'connected': 'connected',
    'sync': 'sync',
    'connecting': 'connecting'
  }

  def request_instance_headers
    { 'apiKey': token.to_s, 'Content-Type': 'application/json' }
  end

  def woofedcrm_webhooks_url
    "#{ENV['FRONTEND_URL']}/apps/evolution_apis/webhooks"
  end


  def generate_token(field)
    loop do
      security_token = SecureRandom.hex(10)
      break security_token unless Apps::EvolutionApi.where(field => security_token).exists?
    end
  end
end
