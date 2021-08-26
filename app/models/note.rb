class Note < ApplicationRecord
  belongs_to :flow_item
  has_one :deal, through: :flow_item
  has_rich_text :content
end
