class Accounts::StagesController < InternalController
  before_action :set_stage, only: %i[show deals]

  def show
    @filter_status_deal = params[:filter_status_deal]
    if @filter_status_deal == 'all'
      @pagy, @deals = pagy(@stage.deals.order(position: :desc), items: 8)
    else
      @pagy, @deals = pagy(@stage.deals.where(status: @filter_status_deal).order(position: :desc), items: 8)
    end
  end

  private

  def set_stage
    @stage = Stage.find(params[:id])
  end
end
