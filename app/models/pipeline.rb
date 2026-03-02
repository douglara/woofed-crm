# == Schema Information
#
# Table name: pipelines
#
#  id         :bigint           not null, primary key
#  name       :string           default(""), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Pipeline < ApplicationRecord
  broadcasts_refreshes
  has_many :stages
  has_many :deals
  accepts_nested_attributes_for :stages, reject_if: :all_blank, allow_destroy: true

  def self.ransackable_attributes(auth_object = nil)
    %w[
      id
      name
      created_at
      updated_at
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[deals stages]
  end
end
