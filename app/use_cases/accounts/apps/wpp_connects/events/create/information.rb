class Accounts::Apps::WppConnects::Events::Create::Information

  def self.call(wpp_connect, contact, message)
    Event.create(
      account: wpp_connect.account,
      kind: 'wpp_connect_information',
      from_me: nil,
      contact: contact,
      content: message,
      app: wpp_connect
    )
  end
end