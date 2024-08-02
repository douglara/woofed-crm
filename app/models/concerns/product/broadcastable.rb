module Product::Broadcastable
  extend ActiveSupport::Concern
  included do
    after_update_commit { deal_products_broadcasts }
    after_create_commit do
      broadcast_append_later_to [account.id, :product], target: 'products', partial: '/accounts/products/product',
                                                        locals: { product: self }
    end

    after_update_commit do
      broadcast_replace_later_to [account.id, :product], target: self, partial: '/accounts/products/product',
                                                         locals: { product: self }
    end
    after_destroy_commit do
      broadcast_remove_to [account.id, :product], target: self
    end

    def deal_products_broadcasts
      deal_products.each do |deal_product|
        broadcast_replace_later_to [account.id, :deal], target: deal_product,
                                                        partial: '/accounts/deals/details/deal_products/deal_product', locals: { deal_product: deal_product }
      end
    end
  end
end
