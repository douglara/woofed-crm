class Accounts::DealAssigneesController < InternalController
  before_action :set_deal_assignee, only: %i[destroy]
  before_action :set_deal, only: %i[new]

  def destroy
    return unless @deal_assignee.destroy

    respond_to do |format|
      format.html do
        redirect_to account_deal_path(current_user.account, @deal_assignee.deal),
                    notice: t('flash_messages.deleted', model: DealAssignee.model_name.human)
      end
      format.turbo_stream
    end
  end

  def new
    @deal_assignee = @deal.deal_assignees.new
  end

  def create
    @deal_assignee = DealAssignee.new(deal_assignees_params)
    if @deal_assignee.save
      respond_to do |format|
        format.html { redirect_to account_deal_path(@deal_assignee.account, @deal_assignee.deal) }
        format.turbo_stream
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def deal_assignees_params
    params.require(:deal_assignee).permit(:user_id, :deal_id)
  end

  def set_deal
    @deal = Deal.find(params[:deal_id])
  end

  def set_deal_assignee
    @deal_assignee = DealAssignee.find(params[:id])
  end
end
