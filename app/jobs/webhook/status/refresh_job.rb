class Webhook::Status::RefreshJob < ApplicationJob
  self.queue_adapter = :good_job
  def perform
    Webhook.active.find_each do |webhook|
      next if webhook.valid_url?

      webhook.inactive!
    end
  end
end
