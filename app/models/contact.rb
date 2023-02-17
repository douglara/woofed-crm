class Contact < ApplicationRecord
  validates :full_name, presence: true
  has_many :flow_items
  has_many :events
  belongs_to :account

  has_and_belongs_to_many :deals
end
