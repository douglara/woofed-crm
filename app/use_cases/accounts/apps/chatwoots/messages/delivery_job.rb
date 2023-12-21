class Accounts::Apps::Chatwoots::Messages::DeliveryJob < ApplicationJob

  self.queue_adapter = :good_job  
  def perform(event_id)
    event = Event.find(event_id)
    if !event.done? && check_scheduled_at(event)
      result = Accounts::Apps::Chatwoots::GetConversationAndSendMessage.call(
        event.app,
        event.contact.additional_attributes['chatwoot_id'],
        event.additional_attributes['chatwoot_inbox_id'],
        event.content.body.to_plain_text
      )
      if result.key?(:ok)
        event.additional_attributes['chatwoot_id'] = result[:ok]['id']
        event.additional_attributes['chatwoot_conversation_id'] = result[:ok]['conversation_id']
        event.done = true
        event.save!
        return {ok: event}
      else
        return {error: result[:error]}
      end
    end
  end
  def check_scheduled_at(event)
    Time.current.in_time_zone > event.scheduled_at
  end
end
