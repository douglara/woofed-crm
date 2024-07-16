module Stage::Broadcastable
  extend ActiveSupport::Concern
  included do
    after_update_commit do
      broadcast_updates
      deals.find_each do |deal|
        broadcast_update_later_to deal, html: name, target: 'broadcast_stage_name'
      end
      pipeline.deals.find_each do |deal|
        broadcast_replace_later_to deal, target: 'stages_nav_desktop',
                                         partial: 'accounts/deals/stages_nav_desktop', locals: { deal: deal }

        broadcast_replace_later_to deal, target: 'stages_nav',
                                         partial: 'components/deals/stages_nav', locals: { deal: deal }
      end
    end

    def broadcast_updates
      broadcast_replace_later_to self, partial: 'accounts/pipelines/stage', locals: { status: 'open' }
    end
  end
end
