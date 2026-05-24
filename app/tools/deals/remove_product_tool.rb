# frozen_string_literal: true

module Deals
  class RemoveProductTool < ApplicationTool
    tool_name 'deals_remove_product'
    description <<~DESC
      Remove a product (deal_product line item) from a deal. The deal's overall total (`total_deal_products_amount_in_cents`) is recalculated automatically inside a transaction. The catalog `Product` itself is not deleted — only the deal↔product link.
      Identifies the deal_product by `deal_id` + `product_id` (not by the join id), so you don't need to look it up first. Returns "Couldn't find DealProduct" when the product is not currently attached to that deal.
      To change a product's quantity or price on a deal, prefer deals_update_product over remove + re-add (which would re-snapshot the catalog values and lose any custom price).
    DESC

    input_schema(
      properties: {
        deal_id:    { type: 'integer', description: 'Deal ID' },
        product_id: { type: 'integer', description: 'Product ID to remove from the deal' }
      },
      required: %w[deal_id product_id]
    )

    def self.call(server_context:, deal_id:, product_id:)
      handle_errors do
        deal_product = DealProduct.find_by!(deal_id: deal_id, product_id: product_id)
        DealProduct::Destroy.new(deal_product).call
        json_response(deal_product.as_json)
      end
    end
  end
end
