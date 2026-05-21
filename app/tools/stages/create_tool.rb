# frozen_string_literal: true

module Stages
  class CreateTool < ApplicationTool
    tool_name 'stages_create'
    description 'Create a new stage inside a pipeline. Position is auto-assigned (acts_as_list) when omitted.'

    input_schema(
      properties: {
        pipeline_id: { type: 'integer', description: 'Pipeline this stage belongs to' },
        name:        { type: 'string',  description: 'Stage name' },
        position:    { type: 'integer', description: 'Position within the pipeline. When omitted, the stage is appended at the end.' }
      },
      required: %w[pipeline_id name]
    )

    def self.call(server_context:, pipeline_id:, name:, position: nil)
      handle_errors do
        pipeline = Pipeline.find(pipeline_id)
        stage = pipeline.stages.new(name: name, position: position)
        if stage.save
          json_response(stage.as_json)
        else
          text_response("Validation failed: #{stage.errors.full_messages.join(', ')}")
        end
      end
    end
  end
end
