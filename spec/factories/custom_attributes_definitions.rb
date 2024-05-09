FactoryBot.define do
  factory :custom_attribute_definition do
    account
    attribute_key { 'cpf' }
    attribute_display_name { 'CPF field' }
    attribute_description { 'Field for cpf' }
    trait :contact_attribute do
      attribute_model { 'contact_attribute' }
    end
    trait :contact_attribute do
      attribute_model { 'contact_attribute' }
    end
    trait :deal_attribute do
      attribute_model { 'deal_attribute' }
    end
  end
end
