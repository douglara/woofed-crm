class Api::V1::Accounts::PipelinesController < Api::V1::InternalController
  def index
    pipelines = Pipeline.includes(:stages).all
    render json: pipelines.as_json(include: { stages: { only: %i[id name position] } }), status: :ok
  end
end
