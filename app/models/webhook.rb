# == Schema Information
#
# Table name: webhooks
#
#  id         :bigint           not null, primary key
#  status     :string           default("active")
#  url        :string           default(""), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Webhook < ApplicationRecord
  validates :url, presence: true, format: URI::DEFAULT_PARSER.make_regexp(%w[http https])
  validates :status, presence: true

  enum status: {
    inactive: 'inactive',
    active: 'active'
  }

  after_update_commit do
    broadcast_replace_later_to "webhooks_#{account_id}", target: self, partial: 'accounts/settings/webhooks/webhook',
                                                         locals: { webhook: self }
  end
  after_create_commit do
    broadcast_append_later_to "webhooks_#{account_id}", target: 'webhooks',
                                                         partial: 'accounts/settings/webhooks/webhook', locals: { webhook: self }
  end
  after_destroy_commit  do
    broadcast_remove_to "webhooks_#{account_id}", target: self
  end
end
