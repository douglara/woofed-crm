class Accounts::Settings::Deals::DealLostReasonsController < InternalController
  before_action :set_deal_lost_reason, only: %i[edit update destroy]

  def index
    @deal_lost_reasons = DealLostReason.all
  end

  def edit; end

  def update
    if @deal_lost_reason.update(deal_lost_reason_params)
      respond_to do |format|
        format.html do
          redirect_to edit_account_settings_deals_deal_lost_reason_path(Current.account, @deal_lost_reason),
                      notice: t('flash_messages.updated', model: DealLostReason.model_name.human)
        end
        format.turbo_stream
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def new
    @deal_lost_reason = DealLostReason.new
  end

  def create
    @deal_lost_reason = DealLostReason.new(deal_lost_reason_params)
    if @deal_lost_reason.save
      respond_to do |format|
        format.html do
          redirect_to account_settings_deals_deal_lost_reasons_path(Current.account),
                      notice: t('flash_messages.created', model: DealLostReason.model_name.human)
        end
        format.turbo_stream
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    if @deal_lost_reason.destroy
      respond_to do |format|
        format.html do
          redirect_to account_settings_deals_deal_lost_reasons_path(Current.account),
                      notice: t('flash_messages.deleted', model: DealLostReason.model_name.human)
        end
      end
    else
      respond_to do |format|
        format.html do
          redirect_to account_settings_deals_deal_lost_reasons_path(Current.account),
                      flash: { error: @deal_lost_reason.errors.full_messages.to_sentence }
        end
      end
    end
  end

  private

  def set_deal_lost_reason
    @deal_lost_reason = DealLostReason.find(params[:id])
  end

  def deal_lost_reason_params
    params.require(:deal_lost_reason).permit(:name)
  end
end
