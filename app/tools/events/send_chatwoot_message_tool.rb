# frozen_string_literal: true

module Events
  class SendChatwootMessageTool < ApplicationTool
    tool_name 'events_send_chatwoot_message'
    description 'Send or schedule a Chatwoot message on a deal or contact timeline. Either send_now or scheduled_at must be provided.'

    input_schema(
      properties: {
        deal_id:           { type: 'integer', description: 'Deal ID this message will be attached to' },
        contact_id:        { type: 'integer', description: 'Contact ID this message will be attached to' },
        content:           { type: 'string',  description: 'Message body' },
        app_id:            { type: 'integer', description: 'Chatwoot app integration ID' },
        chatwoot_inbox_id: { type: 'string',  description: 'Target Chatwoot inbox ID' },
        send_now:          { type: 'boolean', description: 'Send immediately when true; otherwise schedule' },
        scheduled_at:      { type: 'string',  description: 'When to deliver the message (ISO8601 UTC). Required when send_now is false.' }
      },
      required: %w[content app_id chatwoot_inbox_id]
    )

    def self.call(server_context:, content:, app_id:, chatwoot_inbox_id:,
                  deal_id: nil, contact_id: nil, send_now: false, scheduled_at: nil)
      handle_errors do
        return text_response('Provide deal_id or contact_id') if deal_id.blank? && contact_id.blank?
        return text_response('Provide send_now=true or scheduled_at') if !send_now && scheduled_at.blank?

        contact_id ||= Deal.find(deal_id).contact_id
        params = {
          kind: 'chatwoot_message', content: content, title: 'Chatwoot Message',
          app_type: 'Apps::Chatwoot', app_id: app_id,
          additional_attributes: { chatwoot_inbox_id: chatwoot_inbox_id },
          send_now: send_now, scheduled_at: scheduled_at, auto_done: !send_now,
          deal_id: deal_id, contact_id: contact_id, from_me: true
        }.compact

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
