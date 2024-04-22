module CustomAttributes
  extend ActiveSupport::Concern

  def custom_attribute_display_name(attribute_key)
    account.custom_attribute_definitions.where(
      attribute_model: "#{self.class.name.downcase}_attribute",
      attribute_key: attribute_key
    ).first.attribute_display_name
  rescue StandardError
    attribute_key
  end
end
