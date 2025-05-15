class Deal::RecalculateAndSaveAllMonetaryValues
  def initialize(deal)
    @deal = deal
  end

  def call
    ActiveRecord::Base.transaction do
      recalculate_deal
    end
  end

  private

  def recalculate_deal
    @deal.total_deal_products_amount_in_cents = @deal.deal_products.sum(:total_amount_in_cents)
    @deal.save!
  end
end
