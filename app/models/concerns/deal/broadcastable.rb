module Deal::Broadcastable
  extend ActiveSupport::Concern
  included do
    after_destroy_commit { broadcast_remove_to stage, target: self }

    after_update_commit do
      broadcast_updates
      broadcast_update_later_to self, html: name, target: 'broadcast_deal_name'
      broadcast_update_later_to self, html: stage.pipeline.name, target: 'broadcast_pipeline_name'
      broadcast_update_later_to self, html: stage.name, target: 'broadcast_stage_name'
      broadcast_replace_later_to self, target: self, partial: 'accounts/deals/details/show',
                                       locals: { model: self, edit_path: edit_account_deal_path(account, self) }
      broadcast_replace_later_to self, target: 'stages_nav_desktop',
                                       partial: 'accounts/deals/stages_nav_desktop'
      broadcast_replace_later_to self, target: 'stages_nav',
                                       partial: 'components/deals/stages_nav'
    end

    after_create_commit do
      broadcast_replace_later_to stage, target: stage,
                                        partial: 'accounts/pipelines/stage',
                                        locals: { stage: stage, status: 'all' }
    end

    def broadcast_updates
      # broadcast_replace_later_to self, partial: 'accounts/pipelines/deal', locals: { pipeline: pipeline }
      if previous_changes.key?('stage_id')
        previous_changes['stage_id'].each do |stage_id|
          Stage.find(stage_id).broadcast_updates
        end
      end
    end
  end
end
