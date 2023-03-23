class Accounts::Apps::WppConnects::Connections::RefreshStatus

  def self.call()
    Apps::WppConnect.actives.each do | wpp_connect |
      Accounts::Apps::WppConnects::Connection::RefreshStatus.call(wpp_connect.id)
    end
  end
end