# frozen_string_literal: true

class Inertia::Accounts::PipelinesController < Inertia::InternalController
  def search
    pipelines = Pipeline.ransack(params[:query])

    @pagy, @pipelines = pagy(pipelines.result, metadata: %i[page items count pages from last to prev next])
    render json: { data: @pipelines,
                   pagination: pagy_metadata(@pagy) }
  rescue ArgumentError => e
    render json: {
      errors: 'Invalid search parameters',
      details: e.message
    }, status: :unprocessable_entity
  end
end
