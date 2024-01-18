# == Schema Information
#
# Table name: pipelines
#
#  id         :bigint           not null, primary key
#  name       :string           default(""), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#
# Indexes
#
#  index_pipelines_on_account_id  (account_id)
#
class Pipeline < ApplicationRecord
  has_many :stages
  has_many :deals
  belongs_to :account
  accepts_nested_attributes_for :stages, reject_if: :all_blank, allow_destroy: true
end
