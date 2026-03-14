class Plugin < ApplicationRecord
  belongs_to :account

  STATUSES = %w[pending building ready error].freeze

  validates :name, presence: true
  validates :prompt, presence: true
  validates :status, inclusion: { in: STATUSES }

  def self.ransackable_attributes(_auth_object = nil)
    %w[id name description status created_at updated_at]
  end
end
