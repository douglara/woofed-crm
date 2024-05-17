class Accounts::ProductsController < InternalController
  before_action :set_product, only: %i[edit destroy update]
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
      redirect_to account_products_path(current_user.account)
    else
      render :edit, status: :unprocessable_entity
    end
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

  def product_params
    params.require(:product).permit(:identifier, :amount_in_cents, :quantity_available, :description, :name,
                                    attachments_attributes: %i[file _destroy id], custom_attributes: {}, additional_attributes: {})
  end
end
