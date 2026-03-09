# == Schema Information
#
# Table name: stages
#
#  id          :bigint           not null, primary key
#  name        :string           default(""), not null
#  position    :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  pipeline_id :bigint           not null
#
# Indexes
#
#  index_stages_on_pipeline_id  (pipeline_id)
#
# Foreign Keys
#
#  fk_rails_...  (pipeline_id => pipelines.id)
#
class Stage < ApplicationRecord
  include Stage::Decorators
  belongs_to :pipeline, touch: true
  acts_as_list scope: :pipeline
  has_many :deals, dependent: :destroy

  scope :ordered_by_pipeline_and_position, lambda {
                                             joins(:pipeline).order('pipelines.name ASC, stages.position ASC')
                                           }

  def total_amount_deals(filter_deals)
    filter_deals = filter_deals.to_json if filter_deals.is_a?(Hash)
    ::Query::Filter.new(deals, JSON.parse(filter_deals)).call.sum(&:total_amount_in_cents)
  end

  def total_quantity_deals(filter_deals)
    filter_deals = filter_deals.to_json if filter_deals.is_a?(Hash)
    ::Query::Filter.new(deals, JSON.parse(filter_deals)).call.count
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[
      id
      name
      created_at
      updated_at
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[deals pipeline]
  end
end
