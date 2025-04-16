module DealProductConcern
  def permitted_deal_product_params
    %i[product_id deal_id quantity unit_amount_in_cents product_name product_identifier]
  end
end
