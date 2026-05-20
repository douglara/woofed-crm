module Stages
  class ListTool < ApplicationTool
    tool_name 'stages_list'
    description 'List stages, optionally filtered by pipeline. Stages are returned ordered by position.'

    arguments do
      optional(:id).filled(:integer).description('Filter by stage ID')
      optional(:pipeline_id).filled(:integer).description('Filter by pipeline ID')
      optional(:name).filled(:string).description('Filter by stage name (case-insensitive partial match)')
      optional(:page).filled(:integer).description('Page number (default 1)')
      optional(:per_page).filled(:integer).description('Items per page (default 25, max 100)')
    end

    def call(id: nil, pipeline_id: nil, name: nil, page: 1, per_page: 25)
      handle_with_exception do
        scope = Stage.all
        scope = scope.where(id: id) if id.present?
        scope = scope.where(pipeline_id: pipeline_id) if pipeline_id.present?
        scope = scope.where('name ILIKE ?', "%#{name}%") if name.present?

        records, pagination = paginate(scope.order(:pipeline_id, :position), page: page, per_page: per_page)
        {
          data: records.as_json(only: %i[id name position pipeline_id created_at updated_at]),
          pagination: pagination
        }.to_json
      end
    end
  end
end
