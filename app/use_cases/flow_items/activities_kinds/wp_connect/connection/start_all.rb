class FlowItems::ActivitiesKinds::WpConnect::Connection::StartAll

  def self.call()
    wp_connections = FlowItems::ActivitiesKinds::WpConnect.where(enabled: true)
    wp_connections.each do | wp_connect |
      FlowItems::ActivitiesKinds::WpConnect::Connection::Start.call(wp_connect)
    end
    return { ok: wp_connections }
  end
end