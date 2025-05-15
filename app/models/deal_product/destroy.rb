class DealProduct::Destroy
  def initialize(deal_product)
    @deal_product = deal_product
  end

  def call
    ActiveRecord::Base.transaction do
      @deal_product.destroy!
      Deal::RecalculateAndSaveAllMonetaryValues.new(@deal_product.deal).call
    end
    @deal_product
  end
end
