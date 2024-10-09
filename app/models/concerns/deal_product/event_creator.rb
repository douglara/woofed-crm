module DealProduct::EventCreator
  extend ActiveSupport::Concern
  included do
    around_create :create_deal_product_and_event
    around_destroy :destroy_deal_product_and_create_event

    def destroy_deal_product_and_create_event
      transaction do
        create_event_log_destroy
        yield
      end
    end

    def create_deal_product_and_event
      transaction do
        yield
        create_event_log
      end
    end

    private

    def create_event_log
      Event.create!(
        deal:,
        kind: 'deal_product_added',
        done: true,
        from_me: true,
        contact: deal.contact,
        additional_attributes: {
          product_id: product.id,
          deal_id: deal.id,
          product_name: product.name,
          deal_name: deal.name
        }
      )
    end

    def create_event_log_destroy
      product_name = product.name
      deal_name = deal.name
      product_id = product.id
      deal_id = deal.id

      Event.create!(
        deal:,
        kind: 'deal_product_removed',
        done: true,
        from_me: true,
        contact: deal.contact,
        additional_attributes: {
          product_id:,
          deal_id:,
          product_name:,
          deal_name:
        }
      )
    end
  end
end
