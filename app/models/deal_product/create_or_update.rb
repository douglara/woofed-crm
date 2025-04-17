class DealProduct::CreateOrUpdate
  def initialize(deal_product, params)
    @deal_product = deal_product
    @params = params
  end

  def call
    @deal_product.assign_attributes(@params)
    return false if @deal_product.invalid?

    if needs_recalculation?
      ActiveRecord::Base.transaction do
        update_deal_product
        @deal_product.save!
        Deal::RecalculateAndSaveAllMonetaryValues.new(@deal_product.deal).call
      end
    else
      @deal_product.save!
    end

    @deal_product
  end

  private

  def needs_recalculation?
    should_recalculate_base_values?
  end

  def update_deal_product
    recalculate_from_base_values if should_recalculate_base_values?
  end

  def recalculate_from_base_values
    @deal_product.total_amount_in_cents = @deal_product.quantity * @deal_product.unit_amount_in_cents
  end

  def should_recalculate_base_values?
    @deal_product.quantity_changed? || @deal_product.unit_amount_in_cents_changed? || @deal_product.new_record?
  end
end
