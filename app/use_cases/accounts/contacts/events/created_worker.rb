class Accounts::Contacts::Events::CreatedWorker
  include Sidekiq::Worker

  def perform(event_id)
    event = Event.find(event_id)
    Accounts::Contacts::Events::Created.call(event)
  end
end