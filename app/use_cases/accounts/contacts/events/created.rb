class Accounts::Contacts::Events::Created

  def self.call(event)
    if event.kind == 'wpp_connect_message'
      Accounts::Apps::WppConnects::Events::Created.call(event)
    else event.kind == 'chatwoot_message'
      Accounts::Apps::Chatwoots::Messages::DeliveryJob.perform_later(event.id)
    end
  end
end