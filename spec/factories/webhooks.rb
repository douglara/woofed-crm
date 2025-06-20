# == Schema Information
#
# Table name: webhooks
#
#  id         :bigint           not null, primary key
#  status     :string           default("active")
#  url        :string           default(""), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
FactoryBot.define do
  factory :webhook do
    url { 'https://woofedcrm.com' }
    status { 'active' }
  end
  trait :skip_validate do
    to_create { |instance| instance.save(validate: false) }
  end
end
