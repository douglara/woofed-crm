class FlowItems::ActivitiesKinds::WpConnect::Messages::WebhookWorker
  include Sidekiq::Worker

  def perform(event)
    FlowItems::ActivitiesKinds::WpConnect::Messages::Webhook.call(event)
  end
end