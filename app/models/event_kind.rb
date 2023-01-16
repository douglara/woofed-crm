class EventKind < ApplicationRecord
  scope :enabled, -> { where(enabled: true) }
end
