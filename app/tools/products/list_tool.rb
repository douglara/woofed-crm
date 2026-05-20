module Products
  class ListTool < ApplicationTool
    tool_name 'products_list'
    description 'List products in the catalog. Supports partial-match filters and pagination.'

    arguments do
      optional(:id).filled(:integer).description('Filter by product ID')
      optional(:name).filled(:string).description('Filter by product name (case-insensitive partial match)')
      optional(:identifier).filled(:string).description('Filter by SKU/identifier (exact match)')
      optional(:description).filled(:string).description('Filter by description (case-insensitive partial match)')
      optional(:amount_in_cents_min).filled(:integer).description('Minimum amount in cents')
      optional(:amount_in_cents_max).filled(:integer).description('Maximum amount in cents')
      optional(:quantity_available_min).filled(:integer).description('Minimum quantity available')
      optional(:created_from).filled(:string).description('Created on/after this ISO8601 UTC datetime')
      optional(:created_to).filled(:string).description('Created on/before this ISO8601 UTC datetime')
      optional(:updated_from).filled(:string).description('Updated on/after this ISO8601 UTC datetime')
      optional(:updated_to).filled(:string).description('Updated on/before this ISO8601 UTC datetime')
      optional(:custom_attributes).hash.description('Filter by custom_attributes key/value pairs (exact match per key)')
      optional(:page).filled(:integer).description('Page number (default 1)')
      optional(:per_page).filled(:integer).description('Items per page (default 25, max 100)')
    end

    def call(id: nil, name: nil, identifier: nil, description: nil,
             amount_in_cents_min: nil, amount_in_cents_max: nil, quantity_available_min: nil,
             created_from: nil, created_to: nil, updated_from: nil, updated_to: nil,
             custom_attributes: nil, page: 1, per_page: 25)
      handle_with_exception do
        scope = Product.all
        scope = scope.where(id: id) if id.present?
        scope = scope.where('name ILIKE ?', "%#{name}%") if name.present?
        scope = scope.where(identifier: identifier) if identifier.present?
        scope = scope.where('description ILIKE ?', "%#{description}%") if description.present?
        scope = scope.where('amount_in_cents >= ?', amount_in_cents_min) if amount_in_cents_min.present?
        scope = scope.where('amount_in_cents <= ?', amount_in_cents_max) if amount_in_cents_max.present?
        scope = scope.where('quantity_available >= ?', quantity_available_min) if quantity_available_min.present?
        scope = scope.where('created_at >= ?', created_from) if created_from.present?
        scope = scope.where('created_at <= ?', created_to) if created_to.present?
        scope = scope.where('updated_at >= ?', updated_from) if updated_from.present?
        scope = scope.where('updated_at <= ?', updated_to) if updated_to.present?
        custom_attributes&.each do |key, value|
          scope = scope.where('custom_attributes->>? = ?', key.to_s, value.to_s)
        end

        records, pagination = paginate(scope.order(created_at: :desc), page: page, per_page: per_page)
        {
          data: records.as_json(only: %i[id name identifier description amount_in_cents quantity_available
                                         custom_attributes additional_attributes created_at updated_at]),
          pagination: pagination
        }.to_json
      end
    end
  end
end
