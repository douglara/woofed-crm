# frozen_string_literal: true

module Deals
  class RemoveAssigneeTool < ApplicationTool
    tool_name 'deals_remove_assignee'
    description <<~DESC
      Remove a user from the assignees (responsibles) of a deal — used to unassign someone from an opportunity. The deal itself is not deleted; only the deal↔user link is removed.
      Identifies the assignee by `deal_id` + `user_id` (not by the join id), so you don't need to look up the DealAssignee record first. Returns "Couldn't find DealAssignee" when the user is not currently an assignee of that deal.
      To reassign the deal to a different user, call this followed by deals_add_assignee with the new user.
    DESC

    input_schema(
      properties: {
        deal_id: { type: 'integer', description: 'Deal ID' },
        user_id: { type: 'integer', description: 'User ID to remove from the deal assignees' }
      },
      required: %w[deal_id user_id]
    )

    def self.call(server_context:, deal_id:, user_id:)
      handle_errors do
        assignee = DealAssignee.find_by!(deal_id: deal_id, user_id: user_id)
        if assignee.destroy
          json_response(assignee.as_json)
        else
          text_response("Failed to remove assignee: #{assignee.errors.full_messages.join(', ')}")
        end
      end
    end
  end
end
