# frozen_string_literal: true

module Pipelines
  class ListTool < ApplicationTool
    tool_name 'pipelines_list'
    description <<~DESC
      List pipelines in the account, each with its stages (ordered by position) inlined. When called without arguments, returns the first page of all pipelines ordered alphabetically by name.
      Use it either to browse pipelines/stages, or to discover the `pipeline_id` and `stage_id` needed by deals_create / deals_update / stages_create. The full pipeline + stages graph is also available via the `woofed:///pipelines/{id}` resource.
    DESC

    input_schema(
      properties: {
        id:       { type: 'integer', description: 'Filter by pipeline ID' },
        name:     { type: 'string',  description: 'Filter pipelines by name (case-insensitive partial match)' },
        page:     { type: 'integer', description: 'Page number (default 1)' },
        per_page: { type: 'integer', description: 'Items per page (default 25, max 100)' }
      }
    )

    def self.call(server_context:, id: nil, name: nil, page: 1, per_page: 25)
      handle_errors do
        scope = Pipeline.includes(:stages)
        scope = scope.where(id: id) if id.present?
        scope = scope.where('pipelines.name ILIKE ?', "%#{name}%") if name.present?

        records, pagination = paginate(scope.order(:name), page: page, per_page: per_page)
        json_response(
          data: records.map do |pipeline|
            pipeline.as_json(only: %i[id name created_at updated_at]).merge(
              stages: pipeline.stages.order(:position).as_json(only: %i[id name position created_at updated_at])
            )
          end,
          pagination: pagination
        )
      end
    end
  end
end
