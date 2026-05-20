module Pipelines
  class ListTool < ApplicationTool
    tool_name 'pipelines_list'
    description 'List pipelines in the account along with their stages.'

    arguments do
      optional(:id).filled(:integer).description('Filter by pipeline ID')
      optional(:name).filled(:string).description('Filter pipelines by name (case-insensitive partial match)')
      optional(:page).filled(:integer).description('Page number (default 1)')
      optional(:per_page).filled(:integer).description('Items per page (default 25, max 100)')
    end

    def call(id: nil, name: nil, page: 1, per_page: 25)
      handle_with_exception do
        scope = Pipeline.includes(:stages)
        scope = scope.where(id: id) if id.present?
        scope = scope.where('pipelines.name ILIKE ?', "%#{name}%") if name.present?

        records, pagination = paginate(scope.order(:name), page: page, per_page: per_page)
        {
          data: records.map do |pipeline|
            pipeline.as_json(only: %i[id name created_at updated_at]).merge(
              stages: pipeline.stages.order(:position).as_json(only: %i[id name position created_at updated_at])
            )
          end,
          pagination: pagination
        }.to_json
      end
    end
  end
end
