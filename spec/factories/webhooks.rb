# == Schema Information
#
# Table name: webhooks
#
#  id         :bigint           not null, primary key
#  status     :string           default("active")
#  url        :string           default(""), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint
#
# Indexes
#
#  index_webhooks_on_account_id  (account_id)
#
FactoryBot.define do
  factory :webhook do
    account
    url { 'https://woofedcrm.com' }
    status { 'active' }
  end
end
