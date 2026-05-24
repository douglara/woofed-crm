# frozen_string_literal: true

module Products
  class ListTool < ApplicationTool
    tool_name 'products_list'
    description <<~DESC
      List products in the catalog. When called without arguments, returns the first page of all products ordered by most-recently created.
      Use it either to browse the catalog, or to discover the `product_id` needed by deals_add_product. The product with its deal_products is also available via the `woofed:///products/{id}` resource.
      `amount_in_cents` and the `amount_in_cents_min`/`_max` filters are always in cents (e.g. 1000035 = R$ 10,000.35 in the account's currency). `identifier` (SKU) is matched exactly; `name` and `description` use case-insensitive partial match. `custom_attributes` does an exact JSONB key/value match (AND across keys).
    DESC

    input_schema(
      properties: {
        id:                     { type: 'integer', description: 'Filter by product ID' },
        name:                   { type: 'string',  description: 'Filter by product name (case-insensitive partial match)' },
        identifier:             { type: 'string',  description: 'Filter by SKU/identifier (exact match)' },
        description:            { type: 'string',  description: 'Filter by description (case-insensitive partial match)' },
        amount_in_cents_min:    { type: 'integer', description: 'Minimum amount in cents' },
        amount_in_cents_max:    { type: 'integer', description: 'Maximum amount in cents' },
        quantity_available_min: { type: 'integer', description: 'Minimum quantity available' },
        created_from:           { type: 'string',  description: 'Created on/after this ISO8601 UTC datetime' },
        created_to:             { type: 'string',  description: 'Created on/before this ISO8601 UTC datetime' },
        updated_from:           { type: 'string',  description: 'Updated on/after this ISO8601 UTC datetime' },
        updated_to:             { type: 'string',  description: 'Updated on/before this ISO8601 UTC datetime' },
        custom_attributes:      { type: 'object',  description: 'Filter by custom_attributes key/value pairs (exact match per key)' },
        page:                   { type: 'integer', description: 'Page number (default 1)' },
        per_page:               { type: 'integer', description: 'Items per page (default 25, max 100)' }
      }
    )

    def self.call(server_context:, id: nil, name: nil, identifier: nil, description: nil,
                  amount_in_cents_min: nil, amount_in_cents_max: nil, quantity_available_min: nil,
                  created_from: nil, created_to: nil, updated_from: nil, updated_to: nil,
                  custom_attributes: nil, page: 1, per_page: 25)
      handle_errors do
        scope = Product.all
        scope = scope.where(id: id) if id.present?
        scope = scope.where('name ILIKE ?', "%#{name}%") if name.present?
        scope = scope.where(identifier: identifier) if identifier.present?
        scope = scope.where('description ILIKE ?', "%#{description}%") if description.present?
        scope = scope.where('amount_in_cents >= ?', amount_in_cents_min) if amount_in_cents_min.present?
        scope = scope.where('amount_in_cents <= ?', amount_in_cents_max) if amount_in_cents_max.present?
        scope = scope.where('quantity_available >= ?', quantity_available_min) if quantity_available_min.present?
        scope = scope.where('created_at >= ?', created_from) if created_from.present?
        scope = scope.where('created_at <= ?', created_to)   if created_to.present?
        scope = scope.where('updated_at >= ?', updated_from) if updated_from.present?
        scope = scope.where('updated_at <= ?', updated_to)   if updated_to.present?
        custom_attributes&.each do |key, value|
          scope = scope.where('custom_attributes->>? = ?', key.to_s, value.to_s)
        end

        records, pagination = paginate(scope.order(created_at: :desc), page: page, per_page: per_page)
        json_response(
          data: records.as_json(only: %i[id name identifier description amount_in_cents quantity_available
                                         custom_attributes additional_attributes created_at updated_at]),
          pagination: pagination
        )
      end
    end
  end
end
