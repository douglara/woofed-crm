# frozen_string_literal: true

class Apps::Chatwoot::Connection::Refresh
  def initialize(chatwoot)
    @chatwoot = chatwoot
  end

  def call
    if @chatwoot.valid_token?
      @chatwoot.inboxes = Accounts::Apps::Chatwoots::GetInboxes.call(@chatwoot)[:ok]
      @chatwoot.save!
    else
      @chatwoot.inactive!
    end
  end
end
