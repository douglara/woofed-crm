# frozen_string_literal: true

module Deals
  class CreateTool < ApplicationTool
    tool_name 'deals_create'
    description <<~DESC
      Create a new deal (opportunity) for an existing contact. Requires `contact_id` (use contacts_list to discover) and `stage_id` (use stages_list or pipelines_list to discover). `pipeline_id` is inferred from the stage when omitted; if provided it must match the stage's pipeline.
      Side effects: the current user becomes the deal's creator and is added as an assignee automatically; a `deal_opened` event is appended to the timeline; the deal starts in `position` 1 of the chosen stage.
      Use `status: 'won'` / `'lost'` here only when logging a deal whose outcome is already known; for the common case of updating later, start with `open` (default) and call deals_mark_won / deals_mark_lost / deals_update afterwards.
      Products are not attached at creation — use deals_add_product after the deal exists.
    DESC

    input_schema(
      properties: {
        contact_id:        { type: 'integer', description: 'Contact ID this deal belongs to' },
        stage_id:          { type: 'integer', description: 'Stage ID where the deal will be placed' },
        pipeline_id:       { type: 'integer', description: 'Pipeline ID. Must match the pipeline of the stage' },
        name:              { type: 'string',  description: 'Deal name/title' },
        status:            { type: 'string',  description: 'Deal status: open (default), won or lost' },
        lost_reason:       { type: 'string',  description: 'Reason (when status = lost)' },
        custom_attributes: { type: 'object',  description: 'Free-form custom fields' }
      },
      required: %w[contact_id stage_id]
    )

    def self.call(server_context:, contact_id:, stage_id:,
                  pipeline_id: nil, name: nil, status: nil, lost_reason: nil, custom_attributes: nil)
      handle_errors do
        attributes = { contact_id: contact_id, stage_id: stage_id, pipeline_id: pipeline_id,
                       name: name, status: status, lost_reason: lost_reason,
                       custom_attributes: custom_attributes }.compact
        params = ActionController::Parameters.new(attributes).permit!
        deal = DealBuilder.new(current_user(server_context), params).perform

        if Deal::CreateOrUpdate.new(deal, params).call
          json_response(deal.as_json)
        else
          text_response("Validation failed: #{deal.errors.full_messages.join(', ')}")
        end
      end
    end
  end
end
