class Accounts::Contacts::Events::SendNow
  def self.call(event)
    event.send_now = nil
    if event.kind == 'chatwoot_message'
      puts("Debug 1: #{event.inspect}")
      puts("Debug 2: #{DateTime.current}")
      event.update(scheduled_at: DateTime.current)
      Accounts::Apps::Chatwoots::Messages::DeliveryJob.perform_later(event.id)
    else
      event.update(done: true)
    end
  end
end
