module Pipelines
  class UpdateTool < ApplicationTool
    tool_name 'pipelines_update'
    description 'Update an existing pipeline by ID. Only fields provided will be changed.'

    arguments do
      required(:id).filled(:integer).description('Pipeline ID')
      optional(:name).filled(:string).description('Pipeline name')
    end

    def call(id:, **attributes)
      handle_with_exception do
        pipeline = Pipeline.find(id)
        if pipeline.update(attributes.compact)
          pipeline.to_json
        else
          unprocessable_error(pipeline.errors.full_messages)
        end
      end
    end
  end
end
