# frozen_string_literal: true

module Pipelines
  class UpdateTool < ApplicationTool
    tool_name 'pipelines_update'
    description <<~DESC
      Update an existing pipeline by ID — currently this means renaming it. Use pipelines_list to discover the pipeline ID.
      Renaming a pipeline does not affect its stages or the deals inside them; existing deal IDs remain stable. To reorder/rename stages, use stages_update; to add new stages, use stages_create.
    DESC

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
