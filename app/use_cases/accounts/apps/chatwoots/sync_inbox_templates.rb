# frozen_string_literal: true

# Enriches the inbox list with the WhatsApp message templates approved in Chatwoot.
#
# The /inboxes (list) endpoint does not return `message_templates`; only the
# /inboxes/:id (detail) endpoint does. For each official WhatsApp inbox
# (`Channel::Whatsapp`) we fetch the detail and nest a trimmed `message_templates`
# array inside the inbox object, so the rest of the app reads a single jsonb blob
# (`apps_chatwoots.inboxes`). Non-WhatsApp inboxes are returned untouched.
class Accounts::Apps::Chatwoots::SyncInboxTemplates
  WHATSAPP_CHANNEL = 'Channel::Whatsapp'

  def self.call(chatwoot, inboxes)
    return inboxes unless inboxes.is_a?(Array)

    inboxes.map do |inbox|
      next inbox unless inbox['channel_type'] == WHATSAPP_CHANNEL

      detail = fetch_inbox_detail(chatwoot, inbox['id'])
      # Keep the previous inbox object on error so a single failing inbox never
      # wipes templates or aborts the whole refresh.
      next inbox if detail.nil?

      inbox.merge('message_templates' => trim_templates(detail['message_templates']))
    end
  end

  def self.fetch_inbox_detail(chatwoot, inbox_id)
    response = Faraday.get(
      "#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/inboxes/#{inbox_id}",
      {},
      chatwoot.request_headers
    )
    return nil unless response.status == 200

    JSON.parse(response.body)
  rescue Faraday::Error, JSON::ParserError => e
    Rails.logger.error("SyncInboxTemplates failed for inbox #{inbox_id}: #{e.message}")
    nil
  end

  # Store only what the form and the send path need, to keep the jsonb small.
  def self.trim_templates(templates)
    Array(templates).select { |template| template['status'] == 'APPROVED' }.map do |template|
      template.slice('name', 'language', 'category').merge(
        'components' => Array(template['components']).map do |component|
          component.slice('type', 'format', 'text', 'buttons')
        end
      )
    end
  end
end
