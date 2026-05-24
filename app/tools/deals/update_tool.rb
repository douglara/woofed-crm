# frozen_string_literal: true

module Deals
  class UpdateTool < ApplicationTool
    tool_name 'deals_update'
    description <<~DESC
      Update an existing deal by ID. Only fields provided are changed; omitted fields are left untouched. Use deals_list first to discover the deal ID.
      Changing `stage_id` moves the deal across the board (the new stage's `pipeline_id` is inferred). Setting `status: 'won'` or `'lost'` also stamps `won_at` / `lost_at` to now and clears the opposite timestamp — for that common case prefer the dedicated deals_mark_won / deals_mark_lost tools.
      `won_at` / `lost_at` arguments are only honored when the account has manual editing enabled (`deal_allow_edit_lost_at_won_at`); otherwise the system overrides them with `Time.current`.
      Products attached to the deal are not editable here — use deals_add_product / deals_update_product / deals_remove_product. `custom_attributes` replaces the whole JSONB hash.
    DESC

    input_schema(
      properties: {
        id:                { type: 'integer', description: 'Deal ID' },
        name:              { type: 'string',  description: 'Deal name/title' },
        status:            { type: 'string',  description: 'Deal status: open, won or lost' },
        stage_id:          { type: 'integer', description: 'Move deal to a different stage' },
        pipeline_id:       { type: 'integer', description: 'Move deal to a different pipeline (must match stage)' },
        lost_reason:       { type: 'string',  description: 'Reason when status is lost' },
        lost_at:           { type: 'string',  description: 'When the deal was marked lost (ISO8601 UTC)' },
        won_at:            { type: 'string',  description: 'When the deal was marked won (ISO8601 UTC)' },
        custom_attributes: { type: 'object',  description: 'Free-form custom fields' }
      },
      required: ['id']
    )

    def self.call(server_context:, id:,
                  name: nil, status: nil, stage_id: nil, pipeline_id: nil,
                  lost_reason: nil, lost_at: nil, won_at: nil, custom_attributes: nil)
      handle_errors do
        deal = Deal.find(id)
        attributes = { name: name, status: status, stage_id: stage_id, pipeline_id: pipeline_id,
                       lost_reason: lost_reason, lost_at: lost_at, won_at: won_at,
                       custom_attributes: custom_attributes }.compact
        if Deal::CreateOrUpdate.new(deal, attributes).call
          json_response(deal.as_json)
        else
          text_response("Validation failed: #{deal.errors.full_messages.join(', ')}")
        end
      end
    end
  end
end
