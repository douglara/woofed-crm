class Api::V1::Accounts::DealProductsController < Api::V1::InternalController
  def show
    @deal_product = DealProduct.find(params['id'])

    if @deal_product
      render json: @deal_product, include: %i[product deal], status: :ok
    else
      render json: { errors: 'Not found' }, status: :not_found
    end
  end

  def create
    @deal_product = DealProduct.new(deal_product_params)

    if @deal_product.save
      render json: @deal_product, include: %i[product deal], status: :created
    else
      render json: { errors: @deal_product.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def deal_product_params
    params.permit(:product_id, :deal_id)
  end
end
