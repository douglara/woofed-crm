class WebpushSubscription < ApplicationRecord
  belongs_to :user
  belongs_to :account
  validates :endpoint, presence: true
  validates :p256dh_key, presence: true
  validates :auth_key, presence: true, uniqueness: true

  def send_notification(message)
    begin
      Webpush.payload_send(
        message: JSON.generate(message),
        endpoint: endpoint,
        p256dh: p256dh_key,
        auth: auth_key,
        vapid: {
          private_key: ENV['VAPID_PRIVATE_KEY'],
          public_key: ENV['VAPID_PUBLIC_KEY']
        }
      )
    rescue Webpush::ExpiredSubscription => e
      return {error: e.message}
    end
  end
end
