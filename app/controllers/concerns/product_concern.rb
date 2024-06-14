# frozen_string_literal: true

module ProductConcern
  def product_params
    params.require(:product).permit(:identifier, :amount_in_cents, :quantity_available, :description, :name, files: [],
                                                                                                             custom_attributes: {}, additional_attributes: {})
  end
end
