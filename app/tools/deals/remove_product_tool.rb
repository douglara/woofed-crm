# frozen_string_literal: true

module Deals
  class RemoveProductTool < ApplicationTool
    tool_name 'deals_remove_product'
    description 'Remove a product (deal_product line) from a deal. The deal totals are recalculated automatically.'

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
