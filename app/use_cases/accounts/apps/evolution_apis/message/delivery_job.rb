class Accounts::Apps::EvolutionApis::Message::DeliveryJob < ApplicationJob
  self.queue_adapter = :good_job
  def perform(event_id)
    @event = Event.find(event_id)
    if @event.should_delivery_event_scheduled?
      result = Accounts::Apps::EvolutionApis::Message::Send.new(@event).call
      if result.key?(:ok)
        @event.done = true
        @event.additional_attributes.merge!({ 'message_id' => result[:ok]['key']['id'] })
        @event.save!
        { ok: @event }
      else
        { error: result[:error] }
      end
    end
  end
end
