# frozen_string_literal: true

module Deals
  class MarkLostTool < ApplicationTool
    tool_name 'deals_mark_lost'
    description 'Mark a deal as lost. Optionally provide the lost reason and timestamp.'

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
