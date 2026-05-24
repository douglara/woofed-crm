# frozen_string_literal: true

module Events
  class SendWhatsappMessageTool < ApplicationTool
    tool_name 'events_send_whatsapp_message'
    description <<~DESC
      Send or schedule a WhatsApp message (via Evolution API) on a deal or contact timeline. The message is delivered to the contact's WhatsApp and also persisted as an Event on the CRM timeline.

      Prerequisites (discover before calling this tool):
      - `app_id` is required — the ID of the Evolution API (WhatsApp) instance to send from. Get it from apps_evolution_apis_list. Each instance is bound to a specific phone number; if the user mentions which number to send from, use the `phone` filter on apps_evolution_apis_list to find that instance.
      - Only instances with `connection_status: 'connected'` will actually deliver — pick a connected one.
      - Provide either `deal_id` or `contact_id` (or both). When only `deal_id` is given, the contact is resolved from the deal automatically. The contact must have a valid `phone` (E.164) — otherwise the WhatsApp delivery will fail.
      - Provide either `send_now: true` for immediate delivery, or `scheduled_at` (ISO8601 UTC) for a future send. Scheduled events are marked auto-done when delivered.
    DESC

    input_schema(
      properties: {
        deal_id:      { type: 'integer', description: 'Deal ID this message will be attached to' },
        contact_id:   { type: 'integer', description: 'Contact ID this message will be attached to' },
        content:      { type: 'string',  description: 'Message body' },
        app_id:       { type: 'integer', description: 'Evolution API app integration ID' },
        send_now:     { type: 'boolean', description: 'Send immediately when true; otherwise schedule' },
        scheduled_at: { type: 'string',  description: 'When to deliver the message (ISO8601 UTC). Required when send_now is false.' }
      },
      required: %w[content app_id]
    )

    def self.call(server_context:, content:, app_id:,
                  deal_id: nil, contact_id: nil, send_now: false, scheduled_at: nil)
      handle_errors do
        return text_response('Provide deal_id or contact_id') if deal_id.blank? && contact_id.blank?
        return text_response('Provide send_now=true or scheduled_at') if !send_now && scheduled_at.blank?

        contact_id ||= Deal.find(deal_id).contact_id
        params = {
          kind: 'evolution_api_message', content: content, title: 'Whatsapp Message',
          app_type: 'Apps::EvolutionApi', app_id: app_id,
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
