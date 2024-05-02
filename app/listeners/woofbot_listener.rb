# frozen_string_literal: true

class WoofbotListener
  def event_created(event)
    Accounts::Contacts::Events::WoofbotJob.perform_later(event.id) if event.account.woofbot_auto_reply?
  end
end
