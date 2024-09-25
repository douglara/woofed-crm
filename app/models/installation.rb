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
  include Installation::Complete

  validates_presence_of :key1
  validates_presence_of :key2
  validates_presence_of :token

  enum status: {
    initialized: 0,
    in_progress: 1,
    on_hold: 2,
    completed: 3,
    cancelled: 4
  }
  def self.installation_url
    "https://store.woofedcrm.com/installations/new?installation_params=#{{ url: ENV.fetch('FRONTEND_URL', 'http://localhost:3001'),
                                                                           kind: :self_hosted }.to_json}"
  end

  def self.installation_flow?
    User.first.blank? && Installation.first.blank?
  end


  # def self.installation_flow?
  #   User.first.blank?
  # end
end

# def self.installation_flow?
#   (User.first.blank? && Installation.first.blank?) && !Installation.first.completed?
# end
