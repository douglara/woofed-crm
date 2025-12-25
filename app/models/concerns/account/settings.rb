module Account::Settings
  extend ActiveSupport::Concern

  included do
    store_accessor :settings, :free_form_lost_reasons, prefix: :deal
    store_accessor :settings, :allow_edit_lost_at_won_at, prefix: :deal

    def deal_free_form_lost_reasons
      return false if DealLostReason.none?

      super
    end

    def deal_free_form_lost_reasons=(value)
      super(ActiveRecord::Type::Boolean.new.cast(value))
    end

    def deal_allow_edit_lost_at_won_at=(value)
      super(ActiveRecord::Type::Boolean.new.cast(value))
    end
  end
end
