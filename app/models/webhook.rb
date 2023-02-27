class Webhook < ApplicationRecord
  belongs_to :account

  validates :account_id, presence: true
  validates :url, presence: true
end
