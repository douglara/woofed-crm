class Inertia::Accounts::UsersController < Inertia::InternalController
  def search
    users = User.ransack(params[:query])

    @pagy, @users = pagy(users.result, metadata: %i[page items count pages from last to prev next])
    render json: { data: @users,
                   pagination: pagy_metadata(@pagy) }
  rescue ArgumentError => e
    render json: {
      errors: 'Invalid search parameters',
      details: e.message
    }, status: :unprocessable_entity
  end
end
