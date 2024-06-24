# == Schema Information
#
# Table name: stages
#
#  id          :bigint           not null, primary key
#  name        :string           default(""), not null
#  position    :integer          default(1), not null
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
  belongs_to :pipeline
  acts_as_list scope: :pipeline
  has_many :deals, dependent: :destroy

  after_update_commit -> { broadcast_updates }

  def broadcast_updates(status = nil)
    if status
      broadcast_replace_later_to [:stages, status], target: self, partial: 'accounts/pipelines/stage',
                                                    locals: { status: status }
    else
      ::Deal.statuses.each_value do |statuse|
        broadcast_replace_later_to [:stages, statuse], target: self, partial: 'accounts/pipelines/stage',
                                                       locals: { status: statuse }
      end
    end
  end
end
