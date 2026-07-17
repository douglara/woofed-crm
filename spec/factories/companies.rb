# == Schema Information
#
# Table name: companies
#
#  id                    :bigint           not null, primary key
#  additional_attributes :jsonb
#  custom_attributes     :jsonb
#  email                 :string           default(""), not null
#  name                  :string           default(""), not null
#  phone                 :string           default(""), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#
require 'faker'

FactoryBot.define do
  factory :company do
    name { Faker::Company.name }
    email { Faker::Internet.email }
    phone { Faker::PhoneNumber.cell_phone_in_e164 }
    custom_attributes { {} }
    additional_attributes { {} }

    trait :with_contacts do
      transient do
        contacts_count { 2 }
      end

      after(:create) do |company, evaluator|
        create_list(:company_contact, evaluator.contacts_count, company:)
      end
    end
  end
end
