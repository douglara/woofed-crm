# frozen_string_literal: true

module Events
  class CreateActivityTool < ApplicationTool
    tool_name 'events_create_activity'
    description 'Schedule a task/activity (call, meeting, follow-up) on a deal or contact timeline. Provide deal_id or contact_id.'

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
