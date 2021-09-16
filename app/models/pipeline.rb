class Pipeline < ApplicationRecord
  has_many :stages
  accepts_nested_attributes_for :stages, reject_if: :all_blank, allow_destroy: true
end
