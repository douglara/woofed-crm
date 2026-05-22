# frozen_string_literal: true

module Deals
  class AddProductTool < ApplicationTool
    tool_name 'deals_add_product'
    description 'Attach a product to a deal as a deal_product line. The unit_amount_in_cents and the product name/identifier snapshot are pulled from the Product catalog; use deals_update_product afterwards to override them on this deal. Returns a validation error if the product is already attached to the deal.'

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
