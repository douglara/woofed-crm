class Accounts::Apps::EvolutionApis::Message::DeliveryJob < ApplicationJob

  self.queue_adapter = :good_job
  def perform(event_id)
    event = Event.find(event_id)
    if event.should_delivery_message_scheduled?
      result = Accounts::Apps::EvolutionApis::Message::Send.call(
        event.app,
        event.contact.phone,
        event.content.body.to_plain_text
      )
      if result.key?(:ok)
        event.done = true
        event.additional_attributes.merge!({ 'message_id' => result[:ok]['key']['id']})
        event.save!
        SendMessageEventNotifier.with(event: event).deliver(event.account)
        return { ok: event }
      else
        return {error: result[:error]}
      end
    end
  end
end
