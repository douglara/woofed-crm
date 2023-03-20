class Accounts::Apps::WppConnects::Sync::FullSync

  def self.call(wpp_connect_id)
    wpp_connect = Apps::WppConnect.find(wpp_connect_id)
    Accounts::Apps::WppConnects::Sync::Contacts.call(wpp_connect_id)
  end
end