# == Schema Information
#
# Table name: products
#
#  id                    :bigint           not null, primary key
#  additional_attributes :jsonb
#  amount_in_cents       :integer          default(0), not null
#  custom_attributes     :jsonb
#  description           :text             default(""), not null
#  identifier            :string           default(""), not null
#  name                  :string           default(""), not null
#  quantity_available    :integer          default(0), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#
require 'faker'

FactoryBot.define do
  factory :product do
    identifier { Faker::Alphanumeric.alphanumeric(number: 10) }
    amount_in_cents { Faker::Number.between(from: 1, to: 10_000) }
    quantity_available { Faker::Number.within(range: 1..100) }
    description { Faker::Lorem.sentence(word_count: 10) }
    name { Faker::Commerce.product_name }
    custom_attributes { {} }
    additional_attributes { {} }
  end
end
