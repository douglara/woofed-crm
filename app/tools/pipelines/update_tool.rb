# frozen_string_literal: true

module Pipelines
  class UpdateTool < ApplicationTool
    tool_name 'pipelines_update'
    description 'Update an existing pipeline by ID. Only fields provided will be changed.'

    input_schema(
      properties: {
        id:   { type: 'integer', description: 'Pipeline ID' },
        name: { type: 'string',  description: 'Pipeline name' }
      },
      required: ['id']
    )

    def self.call(server_context:, id:, name: nil)
      handle_errors do
        pipeline = Pipeline.find(id)
        if pipeline.update({ name: name }.compact)
          json_response(pipeline.as_json)
        else
          text_response("Validation failed: #{pipeline.errors.full_messages.join(', ')}")
        end
      end
    end
  end
end
