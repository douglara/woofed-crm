class ActivityKind < ApplicationRecord
  scope :enabled, -> { where(enabled: true) }
end
