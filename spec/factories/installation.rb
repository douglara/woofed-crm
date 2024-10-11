# == Schema Information
#
# Table name: installations
#
#  id         :string           not null, primary key
#  key1       :string           default(""), not null
#  key2       :string           default(""), not null
#  status     :integer          default(0), not null
#  token      :string           default(""), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require 'faker'
FactoryBot.define do
  factory :installation do
    id { SecureRandom.uuid }
    key1 { Faker::Alphanumeric.alphanumeric(number: 10) }
    key2 { Faker::Alphanumeric.alphanumeric(number: 10) }
    status { rand(0..1) }
    token { Faker::Alphanumeric.alphanumeric(number: 20) }
    user
  end
end
