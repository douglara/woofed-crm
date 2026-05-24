# frozen_string_literal: true

module Events
  class CreateActivityTool < ApplicationTool
    tool_name 'events_create_activity'
    description <<~DESC
      Schedule a task/activity (call, meeting, follow-up, reminder) on a deal or contact timeline. Activities are internal — they do not send anything to the customer; they're how the team plans and tracks work.
      Provide either `deal_id` or `contact_id` (or both). When only `deal_id` is given, the contact is resolved from the deal automatically, so the activity shows up on both timelines.
      Use `scheduled_at` (ISO8601 UTC) to set when the task is due. Pass `done: true` only to log an activity that already happened (e.g. "logged a call we just finished"); otherwise leave it `false` so the user is reminded.
      For a private note with no due date, use events_create_note. To actually send a message to the customer, use events_send_chatwoot_message or events_send_whatsapp_message.
    DESC

    input_schema(
      properties: {
        deal_id:      { type: 'integer', description: 'Deal ID this activity will be attached to' },
        contact_id:   { type: 'integer', description: 'Contact ID this activity will be attached to' },
        title:        { type: 'string',  description: 'Activity title' },
        content:      { type: 'string',  description: 'Activity description/notes' },
        scheduled_at: { type: 'string',  description: 'When the activity is scheduled (ISO8601 UTC)' },
        done:         { type: 'boolean', description: 'Mark the activity as already done' }
      },
      required: ['title']
    )

    def self.call(server_context:, title:, deal_id: nil, contact_id: nil,
                  content: nil, scheduled_at: nil, done: false)
      handle_errors do
        return text_response('Provide deal_id or contact_id') if deal_id.blank? && contact_id.blank?

        contact_id ||= Deal.find(deal_id).contact_id
        params = { kind: 'activity', title: title, content: content,
                   scheduled_at: scheduled_at, done: done,
                   deal_id: deal_id, contact_id: contact_id, from_me: true }.compact

        event = EventBuilder.new(current_user(server_context), params).build
        if event.save
          json_response(event.as_json)
        else
          text_response("Validation failed: #{event.errors.full_messages.join(', ')}")
        end
      end
    end
  end
end
