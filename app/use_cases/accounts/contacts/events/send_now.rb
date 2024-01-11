class Accounts::Contacts::Events::SendNow

  def self.call(event)
    set_scheduled_at(event)
    if event.kind == 'chatwoot_message'
      Accounts::Apps::Chatwoots::Messages::DeliveryJob.perform_later(event.id)
    else
      event.send_now = nil
      event.update(done: true)
    end
  end
  def self.set_scheduled_at(event)
    if event.scheduled_at.nil?
      # event.send_now = nil
      event.scheduled_at = Time.current
      event.save
    end
  end
end
