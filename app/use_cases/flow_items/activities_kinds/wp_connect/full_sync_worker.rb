class FlowItems::ActivitiesKinds::WpConnect::FullSyncWorker
  include Sidekiq::Worker

  def perform(wp_connect_id)
    wp_connect = FlowItems::ActivitiesKinds::WpConnect.find(wp_connect_id)
    FlowItems::ActivitiesKinds::WpConnect::FullSync.new(wp_connect).call()
  end
end