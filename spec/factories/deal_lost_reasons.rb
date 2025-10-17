# == Schema Information
#
# Table name: deal_lost_reasons
#
#  id         :bigint           not null, primary key
#  name       :string           default(""), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
FactoryBot.define do
  factory :deal_lost_reason do
    name { Faker::Company.catch_phrase }
  end
end
