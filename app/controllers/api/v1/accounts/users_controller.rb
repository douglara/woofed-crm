# frozen_string_literal: true

class Api::V1::Accounts::UsersController < Api::V1::InternalController
  include UserConcern

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

  def create
    @user = User.new(user_params)

    if @user.save
      render json: @user, status: :created
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.permit(*permitted_user_params)
  end
end
