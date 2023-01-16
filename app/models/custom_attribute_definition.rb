class CustomAttributeDefinition < ApplicationRecord
  scope :with_attribute_model, ->(attribute_model) { attribute_model.presence && where(attribute_model: attribute_model) }

  validates :attribute_display_name, presence: true
  validates :attribute_key,
            presence: true,
            uniqueness: { scope: [:account_id, :attribute_model] }
  validates :attribute_model, presence: true

  enum attribute_model: { contact_attribute: 0, deal_attribute: 1 }

  belongs_to :account
end
