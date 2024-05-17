# == Schema Information
#
# Table name: custom_attribute_definitions
#
#  id                       :bigint           not null, primary key
#  attribute_description    :text
#  attribute_display_name   :string
#  attribute_key            :string
#  attribute_model          :integer          default("contact_attribute")
#  attribute_options_select :string
#  attribute_type_field     :integer          default("text_field")
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  account_id               :bigint
#
# Indexes
#
#  index_custom_attribute_definitions_on_account_id  (account_id)
#
class CustomAttributeDefinition < ApplicationRecord
  include CustomAttributeDefinition::Broadcastable
  scope :with_attribute_model, lambda { |attribute_model|
                                 attribute_model.presence && where(attribute_model: attribute_model)
                               }

  validates :attribute_display_name, presence: true
  validates :attribute_key,
            presence: true,
            uniqueness: { scope: %i[account_id attribute_model] }
  validates :attribute_model, presence: true


  enum attribute_model: { contact_attribute: 0, deal_attribute: 1, product_attribute: 2 }
  enum attribute_type_field: {
    text_field: 0,
    date_field: 1,
    select_custom: 2,
    number_field: 3
  }

  belongs_to :account
end
