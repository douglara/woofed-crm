class Api::V1::Accounts::Apps::ChatwootsController < Api::V1::InternalController
  # Returns the synced Chatwoot inboxes, each already carrying its approved
  # WhatsApp `message_templates`, so the embedded widget can build the
  # send-template UI without extra calls.
  def inboxes
    chatwoot = Apps::Chatwoot.first
    render json: { inboxes: chatwoot&.inboxes || [] }, status: :ok
  end
end
