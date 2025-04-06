FactoryBot.define do
  factory :contact do
    full_name { 'Tim Maia' }
    email { Faker::Internet.email }
    phone { Faker::PhoneNumber.cell_phone_in_e164 }
  end
end
