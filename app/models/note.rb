class Note < ApplicationRecord
  include Note::Decorators
  has_one :flow_item, as: :record
  has_one :deal, through: :flow_item

  has_rich_text :content
end
