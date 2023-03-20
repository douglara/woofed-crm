class Accounts::Apps::WppConnects::Events::DeliveryMessageJob < ApplicationJob
  self.queue_adapter = :good_job

  def perform(event_id)
    event = Event.find(event_id)
    Accounts::Apps::WppConnects::Events::DeliveryMessage.call(event)
  end
end