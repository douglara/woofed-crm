# == Schema Information
#
# Table name: pipelines
#
#  id         :bigint           not null, primary key
#  name       :string           default(""), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#
# Indexes
#
#  index_pipelines_on_account_id  (account_id)
#
FactoryBot.define do
  factory :pipeline do
    account
    name { 'sales' }
  end
end
