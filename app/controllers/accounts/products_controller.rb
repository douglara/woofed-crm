class Accounts::ProductsController < InternalController
  include ProductConcern

  before_action :set_product, only: %i[edit destroy update show edit_custom_attributes update_custom_attributes]

  def new
    @product = current_user.account.products.new
    @product.attachments.build
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
      redirect_to edit_account_product_path(current_user.account, @product),
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
    @products = if params[:query].present?
                  Product.where(
                    'name ILIKE :search OR identifier ILIKE :search', search: "%#{params[:query]}%"
                  ).order(updated_at: :desc)
                else
                  Product.all.order(created_at: :desc)
                end

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

  def select_product_search
    @products = if params[:query].present?
                  current_user.account.products.where(
                    'name ILIKE :search', search: "%#{params[:query]}%"
                  ).order(updated_at: :desc).limit(5)
                else
                  current_user.account.products.order(updated_at: :desc).limit(5)
                end
  end

  def show
  end

  private

  def set_product
    @product = current_user.account.products.find(params[:id])
  end
end
