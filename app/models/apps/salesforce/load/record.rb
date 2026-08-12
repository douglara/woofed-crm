# frozen_string_literal: true

# Turns one staged row into a Woofed record.
#
# Every path ends with the staged row marked, so nothing is silently lost: it is
# processed, it is a conflict a human has to resolve, or it failed with a reason.
#
# Re-running is safe by construction. The record mapping decides between creating
# and updating, and a row whose modification stamp has not moved since the last
# sync does nothing at all -- which matters because a catch-up brings back its
# whole window, most of it untouched.
class Apps::Salesforce::Load::Record
  # Models that need more than the mapped fields before they can be saved.
  PREPARERS = {
    'Deal' => Apps::Salesforce::Load::Deals::Prepare,
    'Event' => Apps::Salesforce::Load::Events::Prepare
  }.freeze

  def initialize(sync_record)
    @sync_record = sync_record
  end

  def call
    return sync_record.mark_failed!(I18n.t('apps.salesforce.backfill.mapping_missing')) if object_mapping.blank?

    transformed = transform
    resolved = find_or_build(transformed)
    conflict = conflict_message(resolved, transformed)

    return sync_record.mark_conflict!(conflict) if conflict.present?

    persist(resolved, transformed)
  rescue ActiveRecord::RecordInvalid => e
    sync_record.mark_failed!(e.record.errors.full_messages.to_sentence)
  end

  private

  attr_reader :sync_record

  def transform
    Apps::Salesforce::Transform::Record.new(object_mapping, sync_record.payload).call
  end

  def find_or_build(transformed)
    Apps::Salesforce::Load::Record::FindOrBuild.new(
      sync_record, object_mapping, transformed[:ok][:attributes]
    ).call
  end

  # A value already owned by the record being written is not a collision; a value
  # owned by a different one is, and nobody but a human can say which keeps it.
  def conflict_message(resolved, transformed)
    Apps::Salesforce::Transform::Conflict.call(
      object_mapping.woofed_model, transformed[:ok][:attributes], recordable: resolved[:ok]
    )[:conflict]
  end

  def persist(resolved, transformed)
    mapping = resolved[:mapping]
    return sync_record.mark_processed! if mapping.present? && !mapping.outdated?(system_modstamp)

    result = write(resolved[:ok], transformed[:ok])
    return sync_record.mark_failed!(result[:skip]) if result.key?(:skip)

    upsert_mapping(resolved[:ok], mapping)
    sync_record.mark_processed!
  end

  # `compact` keeps a field Salesforce did not send from clearing the Woofed one;
  # the transform already turned a field it sent empty into an explicit nil.
  def write(recordable, values)
    attributes = values[:attributes].compact
    unknown = unknown_fields(recordable, attributes)
    return { skip: I18n.t('apps.salesforce.load.unknown_field', fields: unknown.join(', ')) } if unknown.any?

    recordable.assign_attributes(attributes)
    merge_jsonb(recordable, :custom_attributes, values[:custom_attributes])
    merge_jsonb(recordable, :additional_attributes, values[:additional_attributes])

    prepared = prepare(recordable)
    return prepared if prepared.key?(:skip)

    recordable.save!
    { ok: recordable }
  end

  # A mapping can outlive the column it points at, and some models answer to a
  # setter they have no column for -- Deal#total_amount_in_cents= is defined by a
  # concern and raises. Reporting the row names the mapping the user has to fix,
  # instead of taking the whole batch down with it.
  def unknown_fields(recordable, attributes)
    attributes.keys.reject { |field| recordable.class.column_names.include?(field.to_s) }
  end

  # A Deal needs a stage, a pipeline and a contact that no Salesforce field
  # carries. Models without such requirements go straight to save.
  def prepare(recordable)
    preparer = PREPARERS[object_mapping.woofed_model]
    return { ok: recordable } if preparer.blank?

    preparer.call(recordable, sync_record, object_mapping)
  end

  # Merged rather than replaced: these columns also hold what the user and other
  # integrations put there.
  def merge_jsonb(recordable, column, values)
    return if values.blank? || !recordable.respond_to?("#{column}=")

    recordable.public_send("#{column}=", recordable.public_send(column).to_h.merge(values))
  end

  def upsert_mapping(recordable, mapping)
    record_mapping = mapping || Apps::Salesforce::RecordMapping.new(
      app_id: sync_record.app_id,
      salesforce_object: sync_record.salesforce_object,
      salesforce_id: sync_record.salesforce_id
    )

    record_mapping.update!(
      recordable: recordable,
      salesforce_system_modstamp: system_modstamp,
      last_synced_at: Time.current,
      sync_status: 'synced',
      sync_error: nil
    )
  end

  def system_modstamp
    sync_record.payload['SystemModstamp']
  end

  def object_mapping
    @object_mapping ||= Apps::Salesforce::ObjectMapping.find_by(
      app_id: sync_record.app_id, salesforce_object: sync_record.salesforce_object
    )
  end
end
