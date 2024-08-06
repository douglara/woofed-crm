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
FactoryBot.define do
  factory :webpush_subscription do
    user
    endpoint { Faker::Internet.url }
    auth_key { Faker::Crypto.sha256 }
    p256dh_key { Faker::Crypto.sha1 }

    trait :valid do
      endpoint { 'https://fcm.googleapis.com/fcm/send/eEsBDBy5AZQ:APA91bGOryF67QoKrXQL-uUSX-TytkoBGKKIf-4NnFULLBwYrJhPEVbTgYfoZJEDWt74NwwT8nQNXAKYeQlG_OF9MJ3T_me27rgHDqIjBYveDxKoyhhqPmawO5UDACZPo8_RafXx4oVm' }
      auth_key { 'nBGI-0iiglciX-YgexhSRA' }
      p256dh_key { 'BJEhinz5Xm1Aa1gjnORCQqOdlLm_WSMTFfklDmV86j6B09uhAIb7PqtD4n2S2RZTu6QxA-eNFJZRtk8j2pKRgUI' }
    end
  end
end
