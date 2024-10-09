class Api::V1::Accounts::ProductsController < Api::V1::InternalController
  def show
    @product = Product.find_by_id(params['id'])

    if @product
      render json: @product, include: %i[deal_products], status: :ok
    else
      render json: { errors: 'Not found' }, status: :not_found
    end
  end

  def create
    @product = Product.new(product_params)

    if @product.save
      render json: @product, status: :created
    else
      render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def search
    products = Product.ransack(params[:query])
    @pagy, @products = pagy(products.result, metadata: %i[page items count pages from last to prev next])

    render json: { data: @products,
                   pagination: pagy_metadata(@pagy) }
  end

  def product_params
    params.permit(:identifier, :amount_in_cents, :quantity_available, :description, :name, attachments_attributes: %i[file _destroy id],
                                                                                           custom_attributes: {}, additional_attributes: {})
  end
end
