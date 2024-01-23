# == Schema Information
#
# Table name: apps_evolution_apis
#
#  id                    :bigint           not null, primary key
#  active                :boolean
#  additional_attributes :jsonb
#  endpoint_url          :string
#  name                  :string
#  phone                 :string
#  status                :string
#  token                 :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  account_id            :bigint           not null
#
# Indexes
#
#  index_apps_evolution_apis_on_account_id  (account_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
FactoryBot.define do
  factory :apps_evolution_api, class: 'Apps::EvolutionApi' do
    account
    status { "inactive" }
    active { false }
    endpoint_url { ENV['EVOLUTION_API_ENDPOINT'] }
    token { "woofedtoken" }
    phone { "5522999999999" }
    name { "Woofed EvolutionApi test" }
  end
end
