# frozen_string_literal: true

class Apps::Chatwoot::Connection::Refresh
  def initialize(chatwoot)
    @chatwoot = chatwoot
  end

  def call
    return @chatwoot.inactive! if @chatwoot.invalid_token?

    inboxes = Accounts::Apps::Chatwoots::GetInboxes.call(@chatwoot)

    if inboxes.key?(:ok)
      @chatwoot.inboxes = inboxes[:ok]
      @chatwoot.save!
    end
    true
  end
end
