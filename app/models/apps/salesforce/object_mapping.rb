# frozen_string_literal: true

# Configuration, written by the user on the mapping screen: which Salesforce
# object becomes which Woofed model, and which field feeds which field.
#
# A handful of rows per install -- one per object -- and they answer "how do I
# translate?". Which specific record became which specific record is
# Apps::Salesforce::RecordMapping.
class Apps::Salesforce::ObjectMapping < ApplicationRecord
  self.table_name = 'apps_salesforce_object_mappings'

  WOOFED_MODELS = %w[Company Contact Deal Event].freeze

  belongs_to :app, class_name: 'Apps::Salesforce'

  validates :salesforce_object, presence: true, uniqueness: { scope: :app_id }
  validates :woofed_model, presence: true, inclusion: { in: WOOFED_MODELS }

  scope :enabled, -> { where(enabled: true) }

  # The fields a SOQL SELECT has to ask for, on top of the ones the sync always
  # needs (Id, SystemModstamp and the relationship ids).
  def salesforce_fields
    field_mappings.filter_map { |mapping| mapping['salesforce_field'].presence }.uniq
  end

  def woofed_field_for(salesforce_field)
    field_mappings.find { |mapping| mapping['salesforce_field'] == salesforce_field }&.dig('woofed_field')
  end
end
