module Stages
  class UpdateTool < ApplicationTool
    tool_name 'stages_update'
    description 'Update an existing stage by ID. Only fields provided will be changed.'

    arguments do
      required(:id).filled(:integer).description('Stage ID')
      optional(:name).filled(:string).description('Stage name')
      optional(:position).filled(:integer).description('New position within the pipeline. acts_as_list reorders siblings automatically.')
    end

    def call(id:, **attributes)
      handle_with_exception do
        stage = Stage.find(id)
        if stage.update(attributes.compact)
          stage.to_json
        else
          unprocessable_error(stage.errors.full_messages)
        end
      end
    end
  end
end
