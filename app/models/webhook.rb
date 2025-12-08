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
  validate :validate_webhook_url, if: :active?
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

  def valid_url?
    return false if url.blank?

    response = Webhook::ApiClient.new(self).post_request

    return false if response.key?(:error)

    true
  rescue Faraday::ConnectionFailed, Faraday::TimeoutError, Faraday::SSLError
    false
  end

  private

  def validate_webhook_url
    return if valid_url?

    errors.add(:url)
  end
end
