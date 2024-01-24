class Accounts::Contacts::Events::EnqueueWorker
  include Sidekiq::Worker

  def perform(event_id)
    event = Event.find(event_id)
    Accounts::Contacts::Events::Enqueue.call(event)
  end
end
