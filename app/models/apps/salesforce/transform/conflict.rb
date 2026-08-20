# frozen_string_literal: true

# Woofed enforces uniqueness that Salesforce does not: `contacts` has a unique
# index on lower(email) and on phone, and `companies` likewise, while a
# Salesforce org happily holds thousands of contacts sharing info@company.com.
#
# So a large fraction of a real import would fail on insert. Detecting it first
# turns "some contacts are missing" into a listed conflict with the reason and
# the record that already owns the value, which a human can then resolve.
class Apps::Salesforce::Transform::Conflict
  UNIQUE_FIELDS = %w[email phone].freeze

  def self.call(woofed_model, attributes, recordable: nil)
    model = Apps::Salesforce::WoofedFields::MODELS.dig(woofed_model, :model)
    return { ok: nil } if model.blank?

    UNIQUE_FIELDS.each do |field|
      owner = existing_owner(model, field, attributes[field], recordable)
      next if owner.blank?

      return { conflict: message(model, field, attributes[field], owner) }
    end

    { ok: nil }
  end

  # `recordable` is the record this row already maps to: it owning the value is
  # not a conflict, it is the record being updated.
  def self.existing_owner(model, field, value, recordable)
    return nil if value.blank? || !model.column_names.include?(field)

    scope = field == 'email' ? model.where(field => value.to_s.downcase) : model.where(field => value)
    scope = scope.where.not(id: recordable.id) if recordable&.persisted?

    scope.first
  end

  def self.message(model, field, value, owner)
    I18n.t(
      'apps.salesforce.conflicts.already_taken',
      field: field, value: value, model: model.model_name.human, id: owner.id
    )
  end

  private_class_method :existing_owner, :message
end
