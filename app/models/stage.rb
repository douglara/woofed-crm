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

  def broadcast_updates
    stage_deals = deals.where(status: 'open').order(:position).limit(8).to_a
    broadcast_replace_later_to [account.id, :stages], target: self, partial: 'accounts/stages/stage', locals:{filter_status_deal: 'open', pagy: 1, deals: stage_deals}
  end
end
