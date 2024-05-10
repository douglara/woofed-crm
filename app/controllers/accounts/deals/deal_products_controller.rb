class Accounts::Deals::DealProductsController < InternalController
  before_action :set_deal, only: %i[index]
  before_action :set_deal_product, only: %i[destroy]

  def index
    @deal_products = @deal.deal_products
  end

  def destroy
    @deal_product.destroy
  end

  private

  def set_deal_product
    @deal_product = current_user.account.deal_products.find(params[:id])
  end

  def set_deal
    @deal = current_user.account.deals.find(params[:deal_id])
  end
end
