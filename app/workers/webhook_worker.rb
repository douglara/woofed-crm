class WebhookWorker
  include Sidekiq::Worker

  def perform(url, payload)
    Faraday.post(
      url,
      payload,
      {'Content-Type': 'application/json'}
    )
  end
end