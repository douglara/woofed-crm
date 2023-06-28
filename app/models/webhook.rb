# == Schema Information
#
# Table name: webhooks
#
#  id         :bigint           not null, primary key
#  url        :string           default(""), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint
#
# Indexes
#
#  index_webhooks_on_account_id  (account_id)
#
class Webhook < ApplicationRecord
  belongs_to :account

  validates :account_id, presence: true
  validates :url, presence: true
end
