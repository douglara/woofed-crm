class Accounts::StagesController < InternalController
  before_action :set_stage, only: %i[show]

  def show
    @filter_deals = params[:filter]
    @pagy, @deals = pagy(Query::Filter.new(@stage.deals, JSON.parse(@filter_deals)).call.order(position: :desc),
                         items: 8)
  end

  private

  def set_stage
    @stage = Stage.find(params[:id])
  end
end
