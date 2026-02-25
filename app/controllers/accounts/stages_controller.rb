class Accounts::StagesController < InternalController
  before_action :set_stage, only: %i[show]

  def show
    @filter_status_deal = params[:filter_status_deal].presence || 'open'

    deals = @stage.deals.includes(:contact, :creator, :users)

    # Apply status filter (backward compatible with existing filter)
    deals = deals.where(status: @filter_status_deal) unless @filter_status_deal == 'all'

    # Apply Ransack filters
    @q = deals.ransack(params[:q])
    @filter_params = params[:q]&.to_unsafe_h || {}

    @pagy, @deals = pagy(@q.result(distinct: true).order(position: :desc), items: 8)
  end

  private

  def set_stage
    @stage = Stage.find(params[:id])
  end
end
