class WebpushSubscription < ApplicationRecord
  belongs_to :user

  def send_notification(message)
    begin
      Webpush.payload_send(
        message: JSON.generate(message),
        endpoint: endpoint,
        p256dh: p256dh_key,
        auth: auth_key,
        vapid: {
          private_key: ENV['WEBPUSH_PRIVATE_KEY'],
          public_key: ENV['WEBPUSH_PUBLIC_KEY']
        }
      )
    rescue Webpush::ExpiredSubscription => e
      return {error: e.message}
    end
  end
end
