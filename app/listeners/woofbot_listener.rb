# frozen_string_literal: true

class WoofbotListener
  def event_created(event)
    Accounts::Contacts::Events::WoofbotWorker.perform_async(event.id) if event.account.woofbot_auto_reply?
  end
end
