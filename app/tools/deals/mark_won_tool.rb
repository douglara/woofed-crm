# frozen_string_literal: true

module Deals
  class MarkWonTool < ApplicationTool
    tool_name 'deals_mark_won'
    description 'Mark a deal as won. Optionally provide the timestamp the deal was won.'

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
