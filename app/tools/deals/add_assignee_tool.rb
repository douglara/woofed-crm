# frozen_string_literal: true

module Deals
  class AddAssigneeTool < ApplicationTool
    tool_name 'deals_add_assignee'
    description <<~DESC
      Assign a user as a responsible (assignee) of a deal — the team member who will work on this opportunity. A deal can have multiple assignees.
      Prerequisites: discover `deal_id` via deals_list and `user_id` via users_list.
      A deal already has an initial assignee (the user who created it) — use this tool to add more, not to set the first one. Returns a validation error if the user is already an assignee of this deal. To replace an assignee, call deals_remove_assignee first then deals_add_assignee with the new user.
    DESC

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
