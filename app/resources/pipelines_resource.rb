class PipelinesResource < ApplicationResource
  uri 'woofed:///pipelines/{id}'
  resource_name 'pipeline'
  description 'A pipeline record, including its stages ordered by position.'
  mime_type 'application/json'

  def content
    pipeline = Pipeline.includes(:stages).find(params[:id])
    JSON.generate(
      pipeline.as_json(only: %i[id name created_at updated_at]).merge(
        stages: pipeline.stages.order(:position).as_json(only: %i[id name position created_at updated_at])
      )
    )
  end
end
