# frozen_string_literal: true

module Deals
  class ListTool < ApplicationTool
    tool_name 'deals_list'
    description <<~DESC
      List deals in the account. When called without arguments, returns the first page of all deals ordered by most-recently created.
      Use it either to browse/query deal data, or to discover a deal's ID — that ID can then be passed to other tools (deals_update, deals_mark_won/lost, deals_add_assignee, deals_add_product, events_*) or used to read the full graph via the `woofed:///deals/{id}` resource (which also includes the contact, stage, pipeline, assignees and deal_products).
      Date range filters: `created_*`, `updated_*`, `won_*`, `lost_*` (ISO8601 UTC, inclusive). `custom_attributes` does an exact JSONB key/value match (AND across keys).
      `total_deal_products_amount_in_cents` is the deal's total revenue in cents, computed as the sum of all attached deal_products — it is not editable directly; change it by adding/updating/removing deal_products with deals_add_product / deals_update_product / deals_remove_product.
    DESC

    input_schema(
      properties: {
        id:                { type: 'integer', description: 'Filter by deal ID' },
        name:              { type: 'string',  description: 'Filter by deal name (case-insensitive partial match)' },
        status:            { type: 'string',  description: 'Filter by status: open, won or lost' },
        stage_id:          { type: 'integer', description: 'Filter by stage ID' },
        pipeline_id:       { type: 'integer', description: 'Filter by pipeline ID' },
        contact_id:        { type: 'integer', description: 'Filter by contact ID' },
        lost_reason:       { type: 'string',  description: 'Filter by lost reason (case-insensitive partial match)' },
        created_from:      { type: 'string',  description: 'Created on/after this ISO8601 UTC datetime' },
        created_to:        { type: 'string',  description: 'Created on/before this ISO8601 UTC datetime' },
        updated_from:      { type: 'string',  description: 'Updated on/after this ISO8601 UTC datetime' },
        updated_to:        { type: 'string',  description: 'Updated on/before this ISO8601 UTC datetime' },
        won_from:          { type: 'string',  description: 'Won on/after this ISO8601 UTC datetime' },
        won_to:            { type: 'string',  description: 'Won on/before this ISO8601 UTC datetime' },
        lost_from:         { type: 'string',  description: 'Lost on/after this ISO8601 UTC datetime' },
        lost_to:           { type: 'string',  description: 'Lost on/before this ISO8601 UTC datetime' },
        custom_attributes: { type: 'object',  description: 'Filter by custom_attributes key/value pairs (exact match per key)' },
        page:              { type: 'integer', description: 'Page number (default 1)' },
        per_page:          { type: 'integer', description: 'Items per page (default 25, max 100)' }
      }
    )

    def self.call(server_context:,
                  id: nil, name: nil, status: nil, stage_id: nil, pipeline_id: nil, contact_id: nil,
                  lost_reason: nil, created_from: nil, created_to: nil, updated_from: nil, updated_to: nil,
                  won_from: nil, won_to: nil, lost_from: nil, lost_to: nil,
                  custom_attributes: nil, page: 1, per_page: 25)
      handle_errors do
        scope = Deal.all
        scope = scope.where(id: id) if id.present?
        scope = scope.where('name ILIKE ?', "%#{name}%") if name.present?
        scope = scope.where(status: status) if status.present?
        scope = scope.where(stage_id: stage_id) if stage_id.present?
        scope = scope.where(pipeline_id: pipeline_id) if pipeline_id.present?
        scope = scope.where(contact_id: contact_id) if contact_id.present?
        scope = scope.where('lost_reason ILIKE ?', "%#{lost_reason}%") if lost_reason.present?
        scope = scope.where('created_at >= ?', created_from) if created_from.present?
        scope = scope.where('created_at <= ?', created_to)   if created_to.present?
        scope = scope.where('updated_at >= ?', updated_from) if updated_from.present?
        scope = scope.where('updated_at <= ?', updated_to)   if updated_to.present?
        scope = scope.where('won_at >= ?', won_from) if won_from.present?
        scope = scope.where('won_at <= ?', won_to)   if won_to.present?
        scope = scope.where('lost_at >= ?', lost_from) if lost_from.present?
        scope = scope.where('lost_at <= ?', lost_to)   if lost_to.present?
        custom_attributes&.each do |key, value|
          scope = scope.where('custom_attributes->>? = ?', key.to_s, value.to_s)
        end

        records, pagination = paginate(scope.order(created_at: :desc), page: page, per_page: per_page)
        json_response(
          data: records.as_json(only: %i[id name status stage_id pipeline_id contact_id position
                                         total_deal_products_amount_in_cents lost_at won_at lost_reason
                                         custom_attributes created_at updated_at]),
          pagination: pagination
        )
      end
    end
  end
end
