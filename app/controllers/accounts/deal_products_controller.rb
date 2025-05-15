class Accounts::DealProductsController < InternalController
  include DealProductConcern

  before_action :set_deal_product, only: %i[destroy]
  before_action :set_deal, only: %i[new]

  def destroy
    if DealProduct::Destroy.new(@deal_product).call
      respond_to do |format|
        format.html do
          redirect_to account_deal_path(current_user.account, @deal_product.deal),
                      notice: t('flash_messages.deleted', model: Product.model_name.human)
        end
        format.turbo_stream
      end
    end
  end

  def new
    @deal_product = @deal.deal_products.new
  end

  def create
    @deal_product = DealProductBuilder.new(deal_product_params).perform
    if DealProduct::CreateOrUpdate.new(@deal_product, {}).call
      @deal_product.reload
      respond_to do |format|
        format.html { redirect_to account_deal_path(@deal_product.account, @deal_product.deal) }
        format.turbo_stream
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def deal_product_params
    params.require(:deal_product).permit(*permitted_deal_product_params)
  end

  def set_deal
    @deal = current_user.account.deals.find(params[:deal_id])
  end

  def set_deal_product
    @deal_product = current_user.account.deal_products.find(params[:id])
  end
end
