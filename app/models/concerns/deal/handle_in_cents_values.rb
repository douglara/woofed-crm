module Deal::HandleInCentsValues
  extend ActiveSupport::Concern
  included do
    %i[
      total_amount_in_cents
    ].each do |attribute|
      define_method("#{attribute}=") do |amount|
        amount = sanitize_amount(amount)
        super(amount)
      end
    end
  end
end
