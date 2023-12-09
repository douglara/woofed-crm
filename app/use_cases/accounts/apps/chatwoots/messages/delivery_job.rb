class Accounts::Apps::Chatwoots::Messages::DeliveryJob < ApplicationJob
  self.queue_adapter = :good_job

  def perform(event_id)
    event = Event.find(event_id)
    #event.scheduled_at.near?(Time.current, within: 5.minutes)
    unless event.done? && !((event.scheduled_at - Time.current.in_time_zone).abs <= 30.seconds)
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
end