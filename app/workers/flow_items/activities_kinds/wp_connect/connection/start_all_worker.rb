class FlowItems::ActivitiesKinds::WpConnect::Connection::StartAllWorker
  include Sidekiq::Worker

  def perform()
    FlowItems::ActivitiesKinds::WpConnect::Connection::StartAll.call()
  end
end