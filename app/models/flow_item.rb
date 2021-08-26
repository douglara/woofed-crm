class FlowItem < ApplicationRecord
  belongs_to :deal
  has_one :note
  accepts_nested_attributes_for :note

  default_scope { order(created_at: :desc) }
end
