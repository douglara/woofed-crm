class Stages::BroadcastUpdates
  include Pagy::Backend
  extend ActionView::RecordIdentifier

  def self.call(stage, filter_status_deal)
    stage_filtered_deals = stage.deals.where(status: filter_status_deal).order(position: :desc).limit(8)
    stage_all_deals = stage.deals.order(position: :desc).limit(8)

    pagy_filtered_deals = Pagy.new(count: stage.deals.where(status: filter_status_deal).count, items: 8)
    pagy_all_deals = Pagy.new(count: stage.deals.count, items: 8)

    stage.broadcast_replace_to :stages, target: dom_id(stage, filter_status_deal),
                                        partial: 'accounts/stages/stage', locals: { filter_status_deal:, pagy: pagy_filtered_deals, deals: stage_filtered_deals }
    stage.broadcast_replace_to :stages, target: dom_id(stage, 'all'),
                                        partial: 'accounts/stages/stage', locals: { filter_status_deal: 'all', pagy: pagy_all_deals, deals: stage_all_deals }
  end
end
