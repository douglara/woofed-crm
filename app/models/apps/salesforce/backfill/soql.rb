# frozen_string_literal: true

# Builds the SELECT for one object out of the user's field mapping.
#
# SOQL has no `SELECT *`, so every field has to be named. The list is what the
# user mapped on the mapping screen, plus what the sync itself needs regardless:
# the id to key the record mapping on, the modification stamp that drives the
# cursor and the skip-if-unchanged check, and whatever relationship fields the
# caller resolved from the object's describe.
#
# The same builder produces both queries of the integration. Without a cursor it
# asks for everything, which is the initial load. With one it asks only for what
# changed since, which is the daily catch-up behind the webhooks.
class Apps::Salesforce::Backfill::Soql
  ALWAYS_SELECTED = %w[Id SystemModstamp].freeze

  def initialize(object_mapping, cursor: nil, extra_fields: [])
    @object_mapping = object_mapping
    @cursor = cursor
    @extra_fields = extra_fields
  end

  def call
    "SELECT #{fields.join(', ')} FROM #{object_mapping.salesforce_object}#{where_clause} ORDER BY SystemModstamp"
  end

  # One call that answers how big the object is, so the caller can choose between
  # paging REST and paying for a bulk job.
  def count
    "SELECT COUNT() FROM #{object_mapping.salesforce_object}#{where_clause}"
  end

  private

  attr_reader :object_mapping, :cursor, :extra_fields

  def fields
    (ALWAYS_SELECTED + Array(extra_fields) + object_mapping.salesforce_fields).uniq
  end

  # An optional SOQL fragment the user set on the mapping, e.g. only
  # opportunities from the last two years. Combined with the cursor when both
  # are present.
  def where_clause
    conditions = [cursor_condition, object_mapping.options['filter'].presence].compact
    return '' if conditions.empty?

    " WHERE #{conditions.join(' AND ')}"
  end

  # The comparison is `>`, so the record that set the mark is not fetched again.
  def cursor_condition
    return nil if cursor.blank?

    "SystemModstamp > #{cursor.utc.iso8601}"
  end
end
