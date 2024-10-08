module DealProduct::EventCreator
  extend ActiveSupport::Concern
  included do
    around_create :create_deal_product_and_event
    around_destroy :destroy_deal_product_and_create_event

    def destroy_deal_product_and_create_event
      transaction do
        product_name = product.name
        deal_name = deal.name
        product_id = product.id
        deal_id = deal.id
        yield
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
    rescue ActiveRecord::RecordInvalid => e
      handle_event_creation_error(e)
    end

    def create_deal_product_and_event
      transaction do
        yield
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
    rescue ActiveRecord::RecordInvalid => e
      handle_event_creation_error(e)
    end

    def handle_event_creation_error(e)
      if e.record.is_a?(DealProduct)
        errors.add(:base, "#{DealProduct.model_name.human} #{e.message}")
      elsif e.record.is_a?(Event)
        errors.add(:base, "#{Event.model_name.human} #{e.message}")
      else
        errors.add(:base, "#{DealProduct.model_name.human} #{Event.model_name.human} #{e.message}")
      end
      raise ActiveRecord::Rollback
    end
  end
end
