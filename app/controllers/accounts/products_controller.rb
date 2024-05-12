class Accounts::ProductsController < InternalController
  before_action :set_product, only: %i[edit destroy update edit_custom_attributes update_custom_attributes]
  before_action :set_deal_product, only: %i[edit update edit_custom_attributes update_custom_attributes]
  def new
    @product = current_user.account.products.new
  end

  def create
    @product = ProductBuilder.new(current_user, product_params).perform
    if @product.save
      redirect_to account_products_path(current_user.account), notice: 'Product was successfully created'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @product.update(product_params)
      if @deal_product.present?
        redirect_to account_deal_path(current_user.account,
                                      @deal_product.deal.id)
      else
        redirect_to account_products_path(current_user.account)
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def edit_custom_attributes
    @custom_attribute_definitions = current_user.account.custom_attribute_definitions.product_attribute
  end

  def update_custom_attributes
    @product.custom_attributes[params[:product][:att_key]] = params[:product][:att_value]
    if @deal_product.present?
      redirect_to account_deal_path(current_user.account,
                                    @deal_product.deal)
    end
    render :edit_custom_attributes, status: :unprocessable_entity unless @product.save
  end

  def index
    @products = current_user.account.products.order(created_at: :desc)
    @pagy, @products = pagy(@products)
  end

  def destroy
    @product.destroy
    respond_to do |format|
      format.html do
        redirect_to account_products_path(current_user.account), notice: 'Product was successfully destroyed.'
      end
      format.json { head :no_content }
    end
  end

  private

  def set_product
    @product = current_user.account.products.find(params[:id])
  end

  def set_deal_product
    @deal_product = current_user.account.deal_products.find(params[:deal_product_id])
  rescue ActiveRecord::RecordNotFound
    @deal_product = nil
  end

  def product_params
    params.require(:product).permit(:identifier, :amount_in_cents, :quantity_available, :description, :name,
                                    attachments_attributes: %i[file _destroy id], custom_attributes: {}, additional_attributes: {})
  end
end
