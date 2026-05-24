# frozen_string_literal: true

module Pipelines
  class CreateTool < ApplicationTool
    tool_name 'pipelines_create'
    description <<~DESC
      Create a new pipeline — a Kanban board representing a sales/operational process. A pipeline is empty on creation; add stage columns to it afterwards with stages_create.
      Pipeline names must be unique within the account.
      Typical setup flow: pipelines_create → stages_create (multiple times, one per column) → deals_create with the resulting stage_id.
    DESC

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
