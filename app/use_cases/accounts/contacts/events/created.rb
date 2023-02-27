class Accounts::Contacts::Events::Created

  def self.call(event)
    if event.kind == 'wpp_connect_message'
      Accounts::Apps::WppConnects::Events::Created.call(event)
    end
  end
end