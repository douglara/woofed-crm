class Accounts::Apps::WppConnects::Events::Created

  def self.call(event)
    if (event.kind == 'wpp_connect_message' && event.from_me == true)
      if (event.scheduled_at.blank?)
        Accounts::Apps::WppConnects::Events::DeliveryMessage.call(event)
      else
        Accounts::Apps::WppConnects::Events::DeliveryMessageJob.set(wait_until: event.scheduled_at).perform_later(event.id)
      end
    end
  end
end