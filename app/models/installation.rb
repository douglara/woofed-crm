# == Schema Information
#
# Table name: installations
#
#  id         :string           not null, primary key
#  key1       :string           default(""), not null
#  key2       :string           default(""), not null
#  status     :integer          default(0), not null
#  token      :string           default(""), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Installation < ApplicationRecord
  def self.installation_url
    "http://localhost:3000/installations/new?installation_params=#{{ url: ENV.fetch('FRONTEND_URL', 'http://localhost:3001'),
                                                                           kind: :self_hosted }.to_json}"
  end

  def self.installation_flow?
    User.first.blank?
  end

  def complete_installation
    unless Installation.installation_flow?
      load "#{Rails.root}/app/controllers/application_controller.rb"
      Rails.application.reload_routes!
    end
  end
end
