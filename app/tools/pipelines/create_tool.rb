# frozen_string_literal: true

module Pipelines
  class CreateTool < ApplicationTool
    tool_name 'pipelines_create'
    description 'Create a new pipeline. Stages are added separately via stages_create.'

    input_schema(
      properties: {
        name: { type: 'string', description: 'Pipeline name' }
      },
      required: ['name']
    )

    def self.call(server_context:, name:)
      handle_errors do
        pipeline = Pipeline.new(name: name)
        if pipeline.save
          json_response(pipeline.as_json)
        else
          text_response("Validation failed: #{pipeline.errors.full_messages.join(', ')}")
        end
      end
    end
  end
end
