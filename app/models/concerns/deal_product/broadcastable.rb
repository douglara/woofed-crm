module DealProduct::Broadcastable
  extend ActiveSupport::Concern
  included do
    after_destroy_commit do
      broadcast_remove_to deal, target: self
    end
    after_create_commit do
      broadcast_append_later_to deal, target: 'deal_products',
                                      partial: '/accounts/deals/details/deal_products/deal_product'
    end
  end
end
