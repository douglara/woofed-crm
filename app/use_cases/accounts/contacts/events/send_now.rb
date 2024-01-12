class Accounts::Contacts::Events::SendNow
  def self.call(event)
    event.send_now = nil
    if event.kind == 'chatwoot_message'
      event.update(scheduled_at: DateTime.current)
      Accounts::Apps::Chatwoots::Messages::DeliveryJob.perform_later(event.id)
    else
      event.update(done: true)
    end
  end
end
