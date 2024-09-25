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
  validates_presence_of :key1
  validates_presence_of :key2
  validates_presence_of :token

  enum status: {
    in_progress: 0,
    completed: 1
  }
  def self.installation_url
    "https://store.woofedcrm.com/installations/new?installation_params=#{{ url: ENV.fetch('FRONTEND_URL', 'http://localhost:3001'),
                                                                           kind: :self_hosted }.to_json}"
  end

  def self.installation_flow?
    Installation.first&.status != 'completed'
    # Installation.first.blank? || Installation.first.in_progress?
  end

  def complete_installation
    return if Installation.installation_flow?

    load "#{Rails.root}/app/controllers/application_controller.rb"
    Rails.application.reload_routes!
  end
end
