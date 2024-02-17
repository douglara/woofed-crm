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
#  account_id :bigint           not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_webpush_subscriptions_on_account_id  (account_id)
#  index_webpush_subscriptions_on_user_id     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (user_id => users.id)
#
class WebpushSubscription < ApplicationRecord
  belongs_to :user
  belongs_to :account

  def send_notification(message)
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
  end

end
