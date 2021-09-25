class Contact < ApplicationRecord
  validates :full_name, presence: true
  has_many :flow_items
end
