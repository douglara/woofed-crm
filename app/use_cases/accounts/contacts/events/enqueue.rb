class Accounts::Contacts::Events::Enqueue

  def self.call(event)
    if event.kind == 'chatwoot_message'
      Accounts::Apps::Chatwoots::Messages::DeliveryJob.set(wait_until: event.scheduled_at).perform_later(event.id)
    end
  end
end
