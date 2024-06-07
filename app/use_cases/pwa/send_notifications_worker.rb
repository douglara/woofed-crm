class Pwa::SendNotificationsWorker
  # self.queue_adapter = :good_job
  include Sidekiq::Worker
  sidekiq_options queue: :chatwoot_webhooks
  def perform(hash_content)
    WebpushSubscription.all.each do |subscription|
      subscription.send_notification(hash_content)
    end
  end
end
