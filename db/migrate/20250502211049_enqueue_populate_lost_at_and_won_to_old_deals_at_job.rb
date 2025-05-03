class EnqueuePopulateLostAtAndWonToOldDealsAtJob < ActiveRecord::Migration[7.1]
  def change
    populate_lost_at_and_won_at_jobs
  end

  private

  def populate_lost_at_and_won_at_jobs
    ::Deal.where(status: %w[won lost]).find_in_batches do |batch|
      batch.each do |deal|
        Deal::Migrations::PopulateDealLostAtAndWonAtJob.perform_later(deal.id)
      end
    end
  end
end
