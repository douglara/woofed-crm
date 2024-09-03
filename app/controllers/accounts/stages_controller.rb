class Accounts::StagesController < InternalController
  before_action :set_stage, only: %i[show deals]

  def show
    @filter_status_deal = if params[:filter_status_deal].present?
                            params[:filter_status_deal]
                          else
                            'open'
                          end
    if @filter_status_deal == 'all'
      @pagy, @deals = pagy(@stage.deals.order(:position), items: 8)
    else
      @pagy, @deals = pagy(@stage.deals.where(status: @filter_status_deal).order(:position), items: 8)
    end
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  private

  def set_stage
    @stage = current_user.account.stages.find(params[:id])
  end
end
