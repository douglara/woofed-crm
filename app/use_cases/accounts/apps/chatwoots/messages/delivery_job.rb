class Accounts::Apps::Chatwoots::Messages::DeliveryJob < ApplicationJob

  self.queue_adapter = :good_job
  def perform(event_id)
    event = Event.find(event_id)
    if event.should_delivery_message_scheduled?
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
        SendMessageEventNotifier.with(event: event).deliver(event.account)
        return {ok: event}
      else
        return {error: result[:error]}
      end
    end
  end
end
