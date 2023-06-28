# == Schema Information
#
# Table name: notes
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Note < ApplicationRecord
  include Note::Decorators
  #has_one :flow_item, as: :record
  has_one :event, as: :record
  has_one :deal, through: :event

  has_rich_text :content
end
