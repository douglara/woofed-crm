module Events
  class SendWhatsappMessageTool < ApplicationTool
    tool_name 'events_send_whatsapp_message'
    description 'Send or schedule a WhatsApp message (Evolution API) on a deal or contact timeline. Either send_now or scheduled_at must be provided.'

    arguments do
      optional(:deal_id).filled(:integer).description('Deal ID this message will be attached to')
      optional(:contact_id).filled(:integer).description('Contact ID this message will be attached to')
      required(:content).filled(:string).description('Message body')
      required(:app_id).filled(:integer).description('Evolution API app integration ID')
      optional(:send_now).filled(:bool).description('Send immediately when true; otherwise schedule')
      optional(:scheduled_at).filled(:string).description('When to deliver the message (ISO8601 UTC). Required when send_now is false.')
    end

    def call(content:, app_id:, deal_id: nil, contact_id: nil, send_now: false, scheduled_at: nil)
      handle_with_exception do
        return unprocessable_error('Provide deal_id or contact_id') if deal_id.blank? && contact_id.blank?
        return unprocessable_error('Provide send_now=true or scheduled_at') if !send_now && scheduled_at.blank?

        contact_id ||= Deal.find(deal_id).contact_id
        params = {
          kind: 'evolution_api_message', content: content, title: 'Whatsapp Message',
          app_type: 'Apps::EvolutionApi', app_id: app_id,
          send_now: send_now, scheduled_at: scheduled_at, auto_done: !send_now,
          deal_id: deal_id, contact_id: contact_id, from_me: true
        }.compact

        event = EventBuilder.new(current_user, params).build
        if event.save
          event.to_json
        else
          unprocessable_error(event.errors.full_messages)
        end
      end
    end
  end
end
