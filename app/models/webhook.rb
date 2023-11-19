# == Schema Information
#
# Table name: webhooks
#
#  id         :bigint           not null, primary key
#  status     :string
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
  validates :status, presence: true
  enum status: { 
    inactive: 'inactive',
    active: 'active'
  }
  after_update_commit{
    broadcast_replace_later_to :webhooks, target: self, partial: 'accounts/settings/webhooks/webhook', locals: {webhook: self}
  }
  after_create_commit{
    broadcast_prepend_later_to :webhooks, target: 'webhooks', partial: 'accounts/settings/webhooks/webhook', locals: {webhook: self}
  }
  after_destroy_commit{
    broadcast_remove_to :webhooks, target: self
  }
end
