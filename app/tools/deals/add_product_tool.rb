# frozen_string_literal: true

module Deals
  class AddProductTool < ApplicationTool
    tool_name 'deals_add_product'
    description <<~DESC
      Attach a product to a deal as a deal_product line item — this is how the deal's revenue (`total_deal_products_amount_in_cents`) is composed. The deal totals are recalculated automatically.
      Prerequisites: discover `deal_id` via deals_list and `product_id` via products_list.
      At attachment time, the product's catalog values (`unit_amount_in_cents`, `name`, `identifier`) are snapshotted onto the deal_product so later edits to the catalog don't retroactively change closed deals. To override the price for this specific deal, call deals_update_product right after.
      `quantity` defaults to 1 and must be >= 1. Returns a validation error if the same product is already attached to this deal — each product can appear only once per deal; to change quantity/price use deals_update_product instead.
    DESC

    input_schema(
      properties: {
        deal_id:    { type: 'integer', description: 'Deal ID' },
        product_id: { type: 'integer', description: 'Product ID to attach' },
        quantity:   { type: 'integer', description: 'Quantity of this product on the deal (default 1, must be >= 1)' }
      },
      required: %w[deal_id product_id]
    )

    def self.call(server_context:, deal_id:, product_id:, quantity: nil)
      handle_errors do
        attributes = { deal_id: deal_id, product_id: product_id, quantity: quantity }.compact
        params = ActionController::Parameters.new(attributes).permit!
        deal_product = DealProductBuilder.new(params).perform

        if DealProduct::CreateOrUpdate.new(deal_product, {}).call
          json_response(deal_product.as_json)
        else
          text_response("Validation failed: #{deal_product.errors.full_messages.join(', ')}")
        end
      end
    end
  end
end
