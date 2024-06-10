# == Schema Information
#
# Table name: webpush_subscriptions
#
#  id         :bigint           not null, primary key
#  auth_key   :string           default(""), not null
#  endpoint   :string           default(""), not null
#  p256dh_key :string           default(""), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_webpush_subscriptions_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class WebpushSubscription < ApplicationRecord
  belongs_to :user
  validates :endpoint, presence: true
  validates :p256dh_key, presence: true
  validates :auth_key, presence: true, uniqueness: true

  def send_notification(message)
    WebPush.payload_send(
      message: JSON.generate(message),
      endpoint: endpoint,
      p256dh: p256dh_key,
      auth: auth_key,
      vapid: {
        private_key: ENV['VAPID_PRIVATE_KEY'],
        public_key: ENV['VAPID_PUBLIC_KEY']
      }
    )
  rescue WebPush::ExpiredSubscription
    destroy
  end
end
