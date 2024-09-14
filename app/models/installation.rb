class Installation < ApplicationRecord
  self.abstract_class = true

  def self.installation_url
    "https://store.woofedcrm.com/installations/new?installation_params=#{{ url: ENV['FRONTEND_URL'],
                                                                           kind: :self_hosted }.to_json}"
  end

  def self.installation_flow?
    User.first.blank?
  end
end
