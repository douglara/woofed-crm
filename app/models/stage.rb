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
  include ActionView::RecordIdentifier
  belongs_to :pipeline
  acts_as_list scope: :pipeline
  has_many :deals, dependent: :destroy

  after_update_commit -> { broadcast_updates }

  def broadcast_updates(filter_status_deal)
    stage_filtered_deals = deals.where(status: filter_status_deal).order(:position).limit(8).to_a
    stage_all_deals = deals.order(:position).limit(8).to_a

    broadcast_replace_later_to [account.id, :stages], target: dom_id(self, filter_status_deal), partial: 'accounts/stages/stage',
                                                      locals: { filter_status_deal:, pagy: 1, deals: stage_filtered_deals }
    broadcast_replace_later_to [account.id, :stages], target: dom_id(self, 'all'), partial: 'accounts/stages/stage',
                                                      locals: { filter_status_deal: 'all', pagy: 1, deals: stage_all_deals }
  end
end
