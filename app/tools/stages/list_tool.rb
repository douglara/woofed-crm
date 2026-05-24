# frozen_string_literal: true

module Stages
  class ListTool < ApplicationTool
    tool_name 'stages_list'
    description <<~DESC
      List stages, optionally filtered by pipeline. When called without arguments, returns the first page of all stages across all pipelines, ordered by pipeline and then by position within the pipeline.
      Use it either to browse stages, or to discover the `stage_id` needed by deals_create / deals_update. Stages are also embedded inside the `woofed:///pipelines/{id}` resource and the pipelines_list response.
      `position` reflects the visual order of the stage column on the pipeline board (left → right).
    DESC

    input_schema(
      properties: {
        id:          { type: 'integer', description: 'Filter by stage ID' },
        pipeline_id: { type: 'integer', description: 'Filter by pipeline ID' },
        name:        { type: 'string',  description: 'Filter by stage name (case-insensitive partial match)' },
        page:        { type: 'integer', description: 'Page number (default 1)' },
        per_page:    { type: 'integer', description: 'Items per page (default 25, max 100)' }
      }
    )

    def self.call(server_context:, id: nil, pipeline_id: nil, name: nil, page: 1, per_page: 25)
      handle_errors do
        scope = Stage.all
        scope = scope.where(id: id) if id.present?
        scope = scope.where(pipeline_id: pipeline_id) if pipeline_id.present?
        scope = scope.where('name ILIKE ?', "%#{name}%") if name.present?

        records, pagination = paginate(scope.order(:pipeline_id, :position), page: page, per_page: per_page)
        json_response(
          data: records.as_json(only: %i[id name position pipeline_id created_at updated_at]),
          pagination: pagination
        )
      end
    end
  end
end
