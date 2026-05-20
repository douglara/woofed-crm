module Pipelines
  class CreateTool < ApplicationTool
    tool_name 'pipelines_create'
    description 'Create a new pipeline. Stages are added separately via stages_create.'

    arguments do
      required(:name).filled(:string).description('Pipeline name')
    end

    def call(name:)
      handle_with_exception do
        pipeline = Pipeline.new(name: name)
        if pipeline.save
          pipeline.to_json
        else
          unprocessable_error(pipeline.errors.full_messages)
        end
      end
    end
  end
end
