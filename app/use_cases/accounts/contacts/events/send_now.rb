class Accounts::Contacts::Events::SendNow
  def self.call(event)
    event.send_now = nil
    if event.chatwoot_message? || event.evolution_api_message?
      event.update(scheduled_at: DateTime.current, auto_done: false)
      if event.chatwoot_message?
        Accounts::Apps::Chatwoots::Messages::DeliveryJob.perform_later(event.id)
      elsif event.evolution_api_message?
        Accounts::Apps::EvolutionApis::Message::DeliveryJob.perform_later(event.id)
      end
    else
      event.update(done: true)
    end
  end
end
