class Accounts::Apps::WppConnects::Events::Created

  def self.call(event)
    if (event.kind == 'wpp_connect_message' && event.from_me == true && event.due.blank?)
      Accounts::Apps::WppConnects::Events::DeliveryMessage.call(event)
    end
  end
end