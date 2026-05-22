# frozen_string_literal: true

module Deals
  class AddAssigneeTool < ApplicationTool
    tool_name 'deals_add_assignee'
    description 'Assign a user as a responsible (assignee) of a deal. Returns a validation error if the user is already assigned to the deal.'

    input_schema(
      properties: {
        deal_id: { type: 'integer', description: 'Deal ID' },
        user_id: { type: 'integer', description: 'User ID to assign as responsible' }
      },
      required: %w[deal_id user_id]
    )

    def self.call(server_context:, deal_id:, user_id:)
      handle_errors do
        deal = Deal.find(deal_id)
        user = User.find(user_id)

        assignee = DealAssignee.new(deal: deal, user: user)
        if assignee.save
          json_response(assignee.as_json)
        else
          text_response("Validation failed: #{assignee.errors.full_messages.join(', ')}")
        end
      end
    end
  end
end
