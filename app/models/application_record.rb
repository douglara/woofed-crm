class ApplicationRecord < ActiveRecord::Base
  include Applicable

  self.abstract_class = true

  def self.human_enum_name(enum_name, enum_value)
    I18n.t("activerecord.attributes.#{model_name
           .i18n_key}.#{enum_name.to_s.pluralize}.#{enum_value}")
  end

  def sanitize_amount(amount)
    amount.is_a?(String) ? amount.gsub(/[^\d-]/, '').to_i : amount
  end
end
