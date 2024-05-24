class Accounts::ProductsController < InternalController
  include ProductConcern

  before_action :set_product, only: %i[edit destroy update edit_custom_attributes update_custom_attributes]

  def new
    @product = current_user.account.products.new
  end

  def create
    @product = ProductBuilder.new(current_user, product_params).perform
    if @product.save
      respond_to do |format|
        format.html do
          redirect_to account_products_path(current_user.account),
                      notice: t('flash_messages.created', model: Product.model_name.human)
        end
        format.turbo_stream
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @product.update(product_params)
      redirect_to account_products_path(current_user.account),
                  notice: t('flash_messages.updated', model: Product.model_name.human)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def edit_custom_attributes
    @custom_attribute_definitions = current_user.account.custom_attribute_definitions.product_attribute
  end

  def update_custom_attributes
    @product.custom_attributes[params[:product][:att_key]] = params[:product][:att_value]
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
        redirect_to account_products_path(current_user.account),
                    notice: t('flash_messages.deleted', model: Product.model_name.human)
      end
      format.json { head :no_content }
    end
  end

  private

  def set_product
    @product = current_user.account.products.find(params[:id])
  end
end
