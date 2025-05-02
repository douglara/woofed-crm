class AddLostAtAndWonAtToDeals < ActiveRecord::Migration[7.1]
  def up
    add_column :deals, :lost_at, :datetime
    add_column :deals, :won_at, :datetime

    say_with_time 'Populating lost_at and won_at for existing deals...' do
      Deal.where(status: %w[won lost]).find_in_batches(batch_size: 1000) do |batch|
        ActiveRecord::Base.transaction do
          batch.each do |deal|
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
        end
      end
    end
  end

  def down
    remove_column :deals, :lost_at
    remove_column :deals, :won_at
  end
end
