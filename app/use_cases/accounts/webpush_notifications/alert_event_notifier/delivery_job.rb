class Accounts::WebpushNotifications::AlertEventNotifier::DeliveryJob < ApplicationJob

  self.queue_adapter = :good_job
  def perform(event_id)
    event = Event.find(event_id)
    AlertEventNotifier.with(event: event).deliver(event.account) if event.should_delivery_message_scheduled?
  end
end
