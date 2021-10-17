class Contacts::FlowItems::ActivitiesKinds::WpConnections::Messages::SyncWorker
  include Sidekiq::Worker

  def perform(contact_id)0
    contact = Contact.find(contact_id)
    Contacts::FlowItems::ActivitiesKinds::WpConnections::Messages::Sync.call(contact)
  end
end