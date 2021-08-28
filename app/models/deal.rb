class Deal < ApplicationRecord
  belongs_to :contact
  belongs_to :stage
  has_many :flow_items
  has_many :notes, through: :flow_items

  accepts_nested_attributes_for :contact
end
