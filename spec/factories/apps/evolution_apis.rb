# == Schema Information
#
# Table name: apps_evolution_apis
#
#  id                    :bigint           not null, primary key
#  active                :boolean          default(TRUE), not null
#  additional_attributes :jsonb
#  connection_status     :string           default("disconnected"), not null
#  endpoint_url          :string           default(""), not null
#  instance              :string           default(""), not null
#  name                  :string           default(""), not null
#  phone                 :string           default(""), not null
#  qrcode                :string           default(""), not null
#  token                 :string           default(""), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#
require 'faker'

FactoryBot.define do
  factory :apps_evolution_api, class: 'Apps::EvolutionApi' do
    account
    active { false }
    endpoint_url { ENV['EVOLUTION_API_ENDPOINT'] }
    token { Faker::Alphanumeric.alpha(number: 20) }
    name { Faker::Name.name }
    instance { Faker::Alphanumeric.alpha(number: 20) }
    trait :connected do
      phone { Faker::PhoneNumber.cell_phone_in_e164 }
      connection_status { 'connected' }
    end
    trait :connecting do
      connection_status { 'connecting' }
      qrcode { 'qrcode_connecting' }
    end
  end
end
