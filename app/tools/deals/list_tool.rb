module Deals
  class ListTool < ApplicationTool
    tool_name 'deals_list'
    description 'List deals in the account. Supports filters by name, status, stage, pipeline, contact, lost reason and date ranges.'

    arguments do
      optional(:id).filled(:integer).description('Filter by deal ID')
      optional(:name).filled(:string).description('Filter by deal name (case-insensitive partial match)')
      optional(:status).filled(:string).description('Filter by status: open, won or lost')
      optional(:stage_id).filled(:integer).description('Filter by stage ID')
      optional(:pipeline_id).filled(:integer).description('Filter by pipeline ID')
      optional(:contact_id).filled(:integer).description('Filter by contact ID')
      optional(:lost_reason).filled(:string).description('Filter by lost reason (case-insensitive partial match)')
      optional(:created_from).filled(:string).description('Created on/after this ISO8601 UTC datetime')
      optional(:created_to).filled(:string).description('Created on/before this ISO8601 UTC datetime')
      optional(:updated_from).filled(:string).description('Updated on/after this ISO8601 UTC datetime')
      optional(:updated_to).filled(:string).description('Updated on/before this ISO8601 UTC datetime')
      optional(:won_from).filled(:string).description('Won on/after this ISO8601 UTC datetime')
      optional(:won_to).filled(:string).description('Won on/before this ISO8601 UTC datetime')
      optional(:lost_from).filled(:string).description('Lost on/after this ISO8601 UTC datetime')
      optional(:lost_to).filled(:string).description('Lost on/before this ISO8601 UTC datetime')
      optional(:custom_attributes).hash.description('Filter by custom_attributes key/value pairs (exact match per key)')
      optional(:page).filled(:integer).description('Page number (default 1)')
      optional(:per_page).filled(:integer).description('Items per page (default 25, max 100)')
    end

    def call(id: nil, name: nil, status: nil, stage_id: nil, pipeline_id: nil, contact_id: nil,
             lost_reason: nil, created_from: nil, created_to: nil, updated_from: nil, updated_to: nil,
             won_from: nil, won_to: nil, lost_from: nil, lost_to: nil,
             custom_attributes: nil, page: 1, per_page: 25)
      handle_with_exception do
        scope = Deal.all
        scope = scope.where(id: id) if id.present?
        scope = scope.where('name ILIKE ?', "%#{name}%") if name.present?
        scope = scope.where(status: status) if status.present?
        scope = scope.where(stage_id: stage_id) if stage_id.present?
        scope = scope.where(pipeline_id: pipeline_id) if pipeline_id.present?
        scope = scope.where(contact_id: contact_id) if contact_id.present?
        scope = scope.where('lost_reason ILIKE ?', "%#{lost_reason}%") if lost_reason.present?
        scope = scope.where('created_at >= ?', created_from) if created_from.present?
        scope = scope.where('created_at <= ?', created_to) if created_to.present?
        scope = scope.where('updated_at >= ?', updated_from) if updated_from.present?
        scope = scope.where('updated_at <= ?', updated_to) if updated_to.present?
        scope = scope.where('won_at >= ?', won_from) if won_from.present?
        scope = scope.where('won_at <= ?', won_to) if won_to.present?
        scope = scope.where('lost_at >= ?', lost_from) if lost_from.present?
        scope = scope.where('lost_at <= ?', lost_to) if lost_to.present?
        custom_attributes&.each do |key, value|
          scope = scope.where('custom_attributes->>? = ?', key.to_s, value.to_s)
        end

        records, pagination = paginate(scope.order(created_at: :desc), page: page, per_page: per_page)
        {
          data: records.as_json(only: %i[id name status stage_id pipeline_id contact_id position
                                         total_deal_products_amount_in_cents lost_at won_at lost_reason
                                         custom_attributes created_at updated_at]),
          pagination: pagination
        }.to_json
      end
    end
  end
end
