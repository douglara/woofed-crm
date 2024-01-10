class Accounts::Contacts::Events::SendNow

  def self.call(event)
    if event.kind == 'chatwoot_message'
      Accounts::Apps::Chatwoots::Messages::DeliveryJob.perform_later(event.id)
    else
      event.send_now = nil
      event.update(done: true)
    end
  end
end
