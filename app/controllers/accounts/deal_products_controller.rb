class Accounts::DealProductsController < InternalController
  before_action :set_deal_product, only: %i[destroy]

  def destroy
    if @deal_product.destroy
      respond_to do |format|
        format.html do
          redirect_to account_deal_path(current_user.account, @deal_product.deal),
                      notice: 'Product was successfully deleted'
        end
        format.turbo_stream
      end
    end
  end

  private

  def set_deal_product
    @deal_product = current_user.account.deal_products.find(params[:id])
  end
end
