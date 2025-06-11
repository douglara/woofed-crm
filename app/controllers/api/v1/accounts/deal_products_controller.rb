class Api::V1::Accounts::DealProductsController < Api::V1::InternalController
  include DealProductConcern
  def show
    @deal_product = DealProduct.find_by_id(params['id'])

    if @deal_product
      render json: @deal_product, include: %i[product deal], status: :ok
    else
      render json: { errors: 'Not found' }, status: :not_found
    end
  end

  def create
    @deal_product = DealProductBuilder.new(deal_product_params).perform

    if DealProduct::CreateOrUpdate.new(@deal_product, {}).call
      render json: @deal_product, include: %i[product deal], status: :created
    else
      render json: { errors: @deal_product.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def deal_product_params
    params.permit(*permitted_deal_product_params)
  end
end
