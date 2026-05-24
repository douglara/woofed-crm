# frozen_string_literal: true

module Deals
  class MarkWonTool < ApplicationTool
    tool_name 'deals_mark_won'
    description <<~DESC
      Mark a deal as won (sale closed). Convenience tool over deals_update: sets `status: 'won'`, stamps `won_at` (defaults to now) and clears `lost_at` / `lost_reason`.
      Use this when the user says "mark deal X as won", "we closed deal Y", etc. The deal stays in its current stage — moving it to a "Won" stage is up to the pipeline configuration, not this tool.
      `won_at` only overrides the default when the account has `deal_allow_edit_lost_at_won_at` enabled; otherwise the system uses `Time.current`.
    DESC

    input_schema(
      properties: {
        id:     { type: 'integer', description: 'Deal ID' },
        won_at: { type: 'string',  description: 'ISO8601 UTC datetime the deal was won. Defaults to now.' }
      },
      required: ['id']
    )

    def self.call(server_context:, id:, won_at: nil)
      handle_errors do
        deal = Deal.find(id)
        attributes = { status: 'won', won_at: won_at }.compact
        if Deal::CreateOrUpdate.new(deal, attributes).call
          json_response(deal.as_json)
        else
          text_response("Validation failed: #{deal.errors.full_messages.join(', ')}")
        end
      end
    end
  end
end
