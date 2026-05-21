# frozen_string_literal: true

module Stages
  class UpdateTool < ApplicationTool
    tool_name 'stages_update'
    description 'Update an existing stage by ID. Only fields provided will be changed.'

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
