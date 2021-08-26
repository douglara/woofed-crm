class Deal < ApplicationRecord
  belongs_to :stage
  has_many :flow_items
  has_many :notes, through: :flow_items
end
