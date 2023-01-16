class Contact < ApplicationRecord
  validates :full_name, presence: true
  has_many :flow_items
  has_many :events

  after_commit :get_messages_wp_connections

  def get_messages_wp_connections
    Contacts::FlowItems::ActivitiesKinds::WpConnections::Messages::SyncWorker.perform_async(self.id)
  end
end
