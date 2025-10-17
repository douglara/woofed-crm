module Account::Settings
  extend ActiveSupport::Concern

  included do
    store_accessor :settings, :free_form_lost_reasons, prefix: :deal

    def deal_free_form_lost_reasons=(value)
      super(ActiveRecord::Type::Boolean.new.cast(value))
    end
  end
end
