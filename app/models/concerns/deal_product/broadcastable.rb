module DealProduct::Broadcastable
  extend ActiveSupport::Concern
  included do
    after_destroy_commit do
      broadcast_remove_to [account.id, :deal], target: self
    end
    after_create_commit do
      broadcast_append_later_to [deal.id, :deal_product], target: 'deal_products',
                                                          partial: '/accounts/deals/details/deal_products/deal_product',
                                                          locals: { deal_product: self }
    end
  end
end
