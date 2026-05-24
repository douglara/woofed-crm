# frozen_string_literal: true

module Stages
  class UpdateTool < ApplicationTool
    tool_name 'stages_update'
    description <<~DESC
      Update an existing stage by ID — rename it and/or move it to a different position within its pipeline. Use stages_list (or pipelines_list, which embeds stages) to discover the ID.
      Changing `position` reorders the siblings automatically (acts_as_list) — pass the target index counting from 1. To move a deal to a different stage, do not change the stage's position; update the deal instead via deals_update with the new `stage_id`.
      A stage cannot be moved across pipelines through this tool.
    DESC

    input_schema(
      properties: {
        id:       { type: 'integer', description: 'Stage ID' },
        name:     { type: 'string',  description: 'Stage name' },
        position: { type: 'integer', description: 'New position within the pipeline. acts_as_list reorders siblings automatically.' }
      },
      required: ['id']
    )

    def self.call(server_context:, id:, name: nil, position: nil)
      handle_errors do
        stage = Stage.find(id)
        if stage.update({ name: name, position: position }.compact)
          json_response(stage.as_json)
        else
          text_response("Validation failed: #{stage.errors.full_messages.join(', ')}")
        end
      end
    end
  end
end
