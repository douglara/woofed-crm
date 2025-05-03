class Deal::Migrations::PopulateDealLostAtAndWonAtJob < ApplicationJob
  self.queue_adapter = :good_job

  def perform(deal_id)
    deal = Deal.find_by(id: deal_id)
    return unless deal

    ActiveRecord::Base.transaction do
      if deal.won?
        latest_won_event = deal.events
                               .where(kind: 'deal_won')
                               .order(created_at: :desc)
                               .select(:created_at)
                               .first
        deal.update_column(:won_at, latest_won_event&.created_at) if latest_won_event
      elsif deal.lost?
        latest_lost_event = deal.events
                                .where(kind: 'deal_lost')
                                .order(created_at: :desc)
                                .select(:created_at)
                                .first
        deal.update_column(:lost_at, latest_lost_event&.created_at) if latest_lost_event
      end
    end
    Rails.logger.info "Processed deal #{deal.id} for lost_at and won_at"
  end
end
