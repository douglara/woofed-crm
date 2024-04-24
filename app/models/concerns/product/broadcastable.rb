module Product::Broadcastable
  extend ActiveSupport::Concern
  included do
    after_create_commit do
      broadcast_prepend_later_to [account.id, :product], target: 'products', partial: '/accounts/products/product',
                                                         locals: { product: self }
    end

    after_update_commit do
      broadcast_replace_later_to [account.id, :product], target: self, partial: '/accounts/products/product',
                                                         locals: { product: self }
    end
    after_destroy_commit do
      broadcast_remove_to [account.id, :product], target: self
    end
  end
end
