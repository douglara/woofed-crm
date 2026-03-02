# frozen_string_literal: true

class Inertia::Accounts::DealsController < Inertia::InternalController
  def search
    deals = Deal.ransack(params[:query])

    @pagy, @deals = pagy(deals.result, metadata: %i[page items count pages from last to prev next])
    render json: { data: @deals,
                   pagination: pagy_metadata(@pagy) }
  rescue ArgumentError => e
    render json: {
      errors: 'Invalid search parameters',
      details: e.message
    }, status: :unprocessable_entity
  end
end
