# frozen_string_literal: true

class Inertia::Accounts::StagesController < Inertia::InternalController
  def search
    stages = Stage.ransack(params[:query])

    @pagy, @stages = pagy(stages.result, metadata: %i[page items count pages from last to prev next])
    render json: { data: @stages,
                   pagination: pagy_metadata(@pagy) }
  rescue ArgumentError => e
    render json: {
      errors: 'Invalid search parameters',
      details: e.message
    }, status: :unprocessable_entity
  end
end
