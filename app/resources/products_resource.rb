# frozen_string_literal: true

class ProductsResource < ApplicationResource
  uri_template 'woofed:///products/{id}'
  resource_name 'product'
  description 'A product record, including the deal_products that reference it.'
  mime_type 'application/json'

  def content
    product = Product.find(params[:id])
    JSON.generate(product.as_json(include: :deal_products))
  end
end
