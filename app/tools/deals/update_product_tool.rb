# frozen_string_literal: true

module Deals
  class UpdateProductTool < ApplicationTool
    tool_name 'deals_update_product'
    description 'Update the quantity and/or unit price of a product already attached to a deal. total_amount_in_cents and the deal totals are recalculated automatically.'

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
