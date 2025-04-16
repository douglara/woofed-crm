class DealProductBuilder
  include DealProductConcern

  def initialize(params)
    @params = params
  end

  def build
    @deal_product = DealProduct.new(deal_product_params)
    set_unit_amount_in_cents
    set_product_identifier
    set_product_name
    @deal_product
  end

  def perform
    build
    @deal_product
  end

  private

  def set_unit_amount_in_cents
    product_amount_in_cents = @deal_product.product&.amount_in_cents
    @deal_product.unit_amount_in_cents = product_amount_in_cents
  end

  def set_product_identifier
    product_identifier = @deal_product.product&.identifier
    @deal_product.product_identifier = product_identifier
  end

  def set_product_name
    product_name = @deal_product.product&.name
    @deal_product.product_name = product_name
  end

  def deal_product_params
    @params.permit(
      *permitted_deal_product_params
    )
  end
end
