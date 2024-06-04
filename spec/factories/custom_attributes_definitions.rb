FactoryBot.define do
  factory :custom_attribute_definition do
    attribute_key { Faker::Alphanumeric.alpha(number: 10) }
    attribute_display_name { Faker::Lorem.words(number: 2).join(' ') }
    attribute_description { Faker::Lorem.sentence }
    trait :contact_attribute do
      attribute_model { 'contact_attribute' }
    end
    trait :product_attribute do
      attribute_model { 'product_attribute' }
    end
    trait :deal_attribute do
      attribute_model { 'deal_attribute' }
    end
  end
end
