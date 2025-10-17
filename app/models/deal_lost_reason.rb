# == Schema Information
#
# Table name: deal_lost_reasons
#
#  id         :bigint           not null, primary key
#  name       :string           default(""), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class DealLostReason < ApplicationRecord
  validates :name, presence: true
end
