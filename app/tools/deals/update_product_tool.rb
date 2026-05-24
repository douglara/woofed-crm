# frozen_string_literal: true

module Deals
  class UpdateProductTool < ApplicationTool
    tool_name 'deals_update_product'
    description <<~DESC
      Update the `quantity` and/or `unit_amount_in_cents` of a product already attached to a deal. `total_amount_in_cents` for this deal_product (= quantity × unit_amount_in_cents) and the deal's overall total (`total_deal_products_amount_in_cents`) are recalculated automatically inside a transaction.
      Identifies the deal_product by `deal_id` + `product_id` (not by the join id), so you don't need to look it up first. The product must already be attached — use deals_add_product first if it isn't.
      Provide at least one of `quantity` / `unit_amount_in_cents`; calling with neither returns "Provide quantity or unit_amount_in_cents to update". `unit_amount_in_cents` is in cents (e.g. 1000035 = R$ 10,000.35). The snapshot fields `product_name` / `product_identifier` are intentionally not editable here.
    DESC

    input_schema(
      properties: {
        deal_id:              { type: 'integer', description: 'Deal ID' },
        product_id:           { type: 'integer', description: 'Product ID (the product must already be attached to the deal)' },
        quantity:             { type: 'integer', description: 'New quantity (must be >= 1)' },
        unit_amount_in_cents: { type: 'integer', description: 'New unit price in cents (overrides the catalog price for this deal_product)' }
      },
      required: %w[deal_id product_id]
    )

    def self.call(server_context:, deal_id:, product_id:, quantity: nil, unit_amount_in_cents: nil)
      handle_errors do
        deal_product = DealProduct.find_by!(deal_id: deal_id, product_id: product_id)
        attributes = { quantity: quantity, unit_amount_in_cents: unit_amount_in_cents }.compact

        return text_response('Provide quantity or unit_amount_in_cents to update') if attributes.empty?

        params = ActionController::Parameters.new(attributes).permit!
        if DealProduct::CreateOrUpdate.new(deal_product, params).call
          json_response(deal_product.as_json)
        else
          text_response("Validation failed: #{deal_product.errors.full_messages.join(', ')}")
        end
      end
    end
  end
end
