module Stages
  class CreateTool < ApplicationTool
    tool_name 'stages_create'
    description 'Create a new stage inside a pipeline. Position is auto-assigned (acts_as_list) when omitted.'

    arguments do
      required(:pipeline_id).filled(:integer).description('Pipeline this stage belongs to')
      required(:name).filled(:string).description('Stage name')
      optional(:position).filled(:integer).description('Position within the pipeline. When omitted, the stage is appended at the end.')
    end

    def call(pipeline_id:, name:, position: nil)
      handle_with_exception do
        pipeline = Pipeline.find(pipeline_id)
        stage = pipeline.stages.new(name: name, position: position)
        if stage.save
          stage.to_json
        else
          unprocessable_error(stage.errors.full_messages)
        end
      end
    end
  end
end
