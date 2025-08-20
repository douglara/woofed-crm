# frozen_string_literal: true

class Api::V1::Accounts::UsersController < Api::V1::InternalController
  def index
    @users = User.all.order(created_at: :desc)
    @pagy, @users = pagy(@users, metadata: %i[page items count pages from last to prev next])

    render json: { data: @users,
                   pagination: pagy_metadata(@pagy) }
  end
end
