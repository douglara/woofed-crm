# frozen_string_literal: true

module Events
  class CreateNoteTool < ApplicationTool
    tool_name 'events_create_note'
    description 'Add a free-text note to a deal or contact timeline. Provide either deal_id or contact_id (or both).'

    input_schema(
      properties: {
        deal_id:    { type: 'integer', description: 'Deal ID this note will be attached to' },
        contact_id: { type: 'integer', description: 'Contact ID this note will be attached to' },
        content:    { type: 'string',  description: 'Note body' },
        title:      { type: 'string',  description: 'Optional note title' }
      },
      required: ['content']
    )

    def self.call(server_context:, content:, deal_id: nil, contact_id: nil, title: nil)
      handle_errors do
        return text_response('Provide deal_id or contact_id') if deal_id.blank? && contact_id.blank?

        contact_id ||= Deal.find(deal_id).contact_id
        params = { kind: 'note', content: content, title: title,
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
