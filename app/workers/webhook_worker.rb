class WebhookWorker
  include Sidekiq::Worker

  def perform(url, payload)
    Faraday.post(
      url,
      payload
    )
  end
end