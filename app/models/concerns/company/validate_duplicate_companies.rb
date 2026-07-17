module Company::ValidateDuplicateCompanies
  extend ActiveSupport::Concern

  included do
    def save(**options)
      super(**options)
    rescue ActiveRecord::RecordNotUnique => e
      handle_unique_constraint_violation(e)
      false
    rescue PG::UniqueViolation => e
      handle_unique_constraint_violation(e)
      false
    end
  end

  private

  def handle_unique_constraint_violation(exception)
    if exception.message.include?('index_companies_on_phone')
      errors.add(:phone, :taken)
    elsif exception.message.include?('index_companies_on_lower_email')
      errors.add(:email, :taken)
    else
      raise exception
    end
  end
end
