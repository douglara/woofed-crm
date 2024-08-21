# == Schema Information
#
# Table name: installations
#
#  id                :string           not null, primary key
#  app_private_key   :string
#  server_public_key :string
#  token             :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
class Installation < ApplicationRecord
  def self.installation_url
    "https://store.woofedcrm.com/installations/new?installation_params=#{{ url: ENV['FRONTEND_URL'],
                                                                           kind: :self_hosted }.to_json}"
  end

  def self.installation_flow?
    ENV['ENABLE_WOOFEDSTORE'] == 'true' && Installation.first.blank?
  end
end
