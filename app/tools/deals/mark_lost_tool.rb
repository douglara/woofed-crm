# frozen_string_literal: true

module Deals
  class MarkLostTool < ApplicationTool
    tool_name 'deals_mark_lost'
    description <<~DESC
      Mark a deal as lost (opportunity dropped). Convenience tool over deals_update: sets `status: 'lost'`, stamps `lost_at` (defaults to now) and clears `won_at`. `lost_reason` is recommended so the team understands why the deal was lost — it's commonly aggregated in reporting.
      Use this when the user says "mark deal X as lost", "we lost deal Y because the prospect went with a competitor", etc.
      `lost_at` only overrides the default when the account has `deal_allow_edit_lost_at_won_at` enabled; otherwise the system uses `Time.current`.
    DESC

    input_schema(
      properties: {
        id:          { type: 'integer', description: 'Deal ID' },
        lost_reason: { type: 'string',  description: 'Why the deal was lost' },
        lost_at:     { type: 'string',  description: 'ISO8601 UTC datetime the deal was lost. Defaults to now.' }
      },
      required: ['id']
    )

    def self.call(server_context:, id:, lost_reason: nil, lost_at: nil)
      handle_errors do
        deal = Deal.find(id)
        attributes = { status: 'lost', lost_reason: lost_reason, lost_at: lost_at }.compact
        if Deal::CreateOrUpdate.new(deal, attributes).call
          json_response(deal.as_json)
        else
          text_response("Validation failed: #{deal.errors.full_messages.join(', ')}")
        end
      end
    end
  end
end
