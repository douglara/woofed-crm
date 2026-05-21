# frozen_string_literal: true

module Deals
  class CreateTool < ApplicationTool
    tool_name 'deals_create'
    description 'Create a new deal. Requires contact_id and stage_id; pipeline_id is inferred from the stage when omitted.'

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
