# frozen_string_literal: true

# Fills in what a Woofed event needs and a Salesforce task or event does not
# carry: a kind, the contact it belongs to, and the deal it concerns.
#
# Everything else -- the subject, the description, the date -- is the user's
# mapping, because only they know which Salesforce field means what in their org.
class Apps::Salesforce::Load::Events::Prepare
  # Salesforce tasks and events are activities in Woofed terms; the other kinds
  # are things Woofed itself produces, like a message or a stage change.
  DEFAULT_KIND = 'activity'

  def self.call(event, sync_record, object_mapping)
    new(event, sync_record, object_mapping).call
  end

  def initialize(event, sync_record, object_mapping)
    @event = event
    @sync_record = sync_record
    @object_mapping = object_mapping
  end

  def call
    contact = event.contact || Apps::Salesforce::Load::Events::FindContact.call(sync_record)
    return { skip: I18n.t('apps.salesforce.load.event_contact_not_found') } if contact.blank?

    event.contact = contact
    event.kind = kind
    event.deal ||= deal
    mark_done

    { ok: event }
  end

  private

  attr_reader :event, :sync_record, :object_mapping

  def kind
    configured = object_mapping.options['kind'].to_s

    Event.kinds.key?(configured) ? configured : DEFAULT_KIND
  end

  # A task logged against an opportunity belongs to that deal's timeline.
  def deal
    Apps::Salesforce::Load::FindMapped.call(sync_record, salesforce_field: 'WhatId', recordable_type: 'Deal')
  end

  # Salesforce marks a finished task with IsClosed; Woofed shows an activity as
  # done by when it was done.
  def mark_done
    return if event.done_at.present? || !truthy?(sync_record.payload['IsClosed'])

    event.done_at = Apps::Salesforce::Transform::Datetime.call(sync_record.payload['ActivityDate'])[:ok] ||
                    Time.current
  end

  def truthy?(value)
    Apps::Salesforce::Transform::Boolean.call(value)[:ok] == true
  end
end
