# frozen_string_literal: true

# Picks a transform when the mapping does not name one.
#
# The mapping screen asks the user which field feeds which field, not how to
# convert it -- asking would be a question most users cannot answer. The target
# column already carries the answer: an `_in_cents` integer needs cents, a
# datetime column needs a parsed time, a phone column needs E.164.
class Apps::Salesforce::Transform::Inferred
  COLUMN_TYPE_TRANSFORMS = {
    datetime: 'datetime',
    date: 'datetime',
    boolean: 'boolean'
  }.freeze

  def self.call(woofed_model, woofed_field, kind: 'attribute')
    # A custom attribute is stored in jsonb, which has no column type to read.
    return 'text' if kind.to_s == 'custom_attribute'
    return 'phone' if woofed_field.to_s == 'phone'
    return 'currency_to_cents' if woofed_field.to_s.end_with?('_in_cents')

    column = column_for(woofed_model, woofed_field)
    COLUMN_TYPE_TRANSFORMS.fetch(column&.type, 'text')
  end

  def self.column_for(woofed_model, woofed_field)
    model = Apps::Salesforce::WoofedFields::MODELS.dig(woofed_model, :model)

    model&.columns_hash&.dig(woofed_field.to_s)
  end

  private_class_method :column_for
end
