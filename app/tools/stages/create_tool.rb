# frozen_string_literal: true

module Stages
  class CreateTool < ApplicationTool
    tool_name 'stages_create'
    description <<~DESC
      Create a new stage (column) inside an existing pipeline. Use pipelines_list to discover the pipeline ID, or pipelines_create first if the pipeline doesn't exist yet.
      `position` is the order of the column from left to right on the board. When omitted, the new stage is appended at the rightmost end (acts_as_list). Passing a position in the middle pushes existing stages to the right automatically.
      Stages don't carry semantics beyond their name and position — there's no built-in "won" or "lost" stage; outcomes are driven by `deal.status`, not by which stage the deal sits in.
    DESC

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
