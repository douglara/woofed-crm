class Api::V1::Accounts::DealAssigneesController < Api::V1::InternalController
  before_action :set_deal_assignee, only: %i[destroy]

  def destroy
    if @deal_assignee.destroy
      head :no_content
    else
      render json: { errors: @deal_assignee.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def create
    @deal_assignee = DealAssignee.new(deal_assignees_params)

    if @deal_assignee.save
      render json: @deal_assignee, status: :created
    else
      render json: { errors: @deal_assignee.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def deal_assignees_params
    params.permit(:user_id, :deal_id)
  end

  def set_deal_assignee
    @deal_assignee = DealAssignee.find(params[:id])
  end
end
