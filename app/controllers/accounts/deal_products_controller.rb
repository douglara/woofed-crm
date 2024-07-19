class Accounts::DealProductsController < InternalController
  before_action :set_deal_product, only: %i[destroy]
  before_action :set_deal, only: %i[new]

  def destroy
    if @deal_product.destroy
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
    @deal_product = current_user.account.deal_products.new(deal_product_params)
    if @deal_product.save
      respond_to do |format|
        format.html { redirect_to account_deal_path(@deal_product.account, @deal_product.deal) }
        format.turbo_stream
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def select_product_search
    @products = if params[:query].present?
                  current_user.account.products.where(
                    'name ILIKE :search', search: "%#{params[:query]}%"
                  ).order(updated_at: :desc).limit(5)
                else
                  current_user.account.products.order(updated_at: :desc).limit(5)
                end
  end

  private

  def deal_product_params
    params.require(:deal_product).permit(:product_id, :deal_id)
  end

  def set_deal
    @deal = current_user.account.deals.find(params[:deal_id])
  end

  def set_deal_product
    @deal_product = current_user.account.deal_products.find(params[:id])
  end
end
