class Accounts::Apps::EvolutionApis::Message::DeliveryJob < ApplicationJob

  self.queue_adapter = :good_job
  def perform(event_id)
    event = Event.find(event_id)
    if should_delivery?(event)
      result = Accounts::Apps::EvolutionApis::Message::Send.call(
        event.app,
        event.contact.phone,
        event.content
      )
      if result.key?(:ok)
        event.done = true
        event.additional_attributes.merge!({ 'message_id' => result[:ok]['key']['id']})
        event.save!
        return { ok: event }
      else
        return {error: result[:error]}
      end
    end
  end
  def should_delivery?(event)
    !event.done? && (Time.current.in_time_zone > event.scheduled_at)
  end
end
