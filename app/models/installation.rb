class Installation < ApplicationRecord
  self.abstract_class = true

  def self.installation_url
    "https://store.woofedcrm.com/installations/new?installation_params=#{{ url: ENV.fetch('FRONTEND_URL', 'http://localhost:3001'),
                                                                           kind: :self_hosted }.to_json}"
  end

  def self.installation_flow?
    User.first.blank?
  end
end
