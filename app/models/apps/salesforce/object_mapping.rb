# frozen_string_literal: true

# == Schema Information
#
# Table name: apps_salesforce_object_mappings
#
#  id                :bigint           not null, primary key
#  enabled           :boolean          default(FALSE), not null
#  field_mappings    :jsonb            not null
#  options           :jsonb            not null
#  salesforce_object :string           not null
#  woofed_model      :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  app_id            :bigint           not null
#
# Indexes
#
#  index_apps_salesforce_object_mappings_on_app_id     (app_id)
#  index_salesforce_object_mappings_on_app_and_object  (app_id,salesforce_object) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (app_id => apps_salesforces.id)
#
# Configuration, written by the user on the mapping screen: which Salesforce
# object becomes which Woofed model, and which field feeds which field.
#
# A handful of rows per install -- one per object -- and they answer "how do I
# translate?". Which specific record became which specific record is
# Apps::Salesforce::RecordLink.
class Apps::Salesforce::ObjectMapping < ApplicationRecord
  self.table_name = 'apps_salesforce_object_mappings'

  include Apps::Salesforce::ObjectMapping::DealFields

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
