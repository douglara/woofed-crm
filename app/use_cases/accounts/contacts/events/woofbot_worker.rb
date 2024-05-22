# frozen_string_literal: true

class Accounts::Contacts::Events::WoofbotWorker
  include Sidekiq::Worker

  def perform(event_id)
    event = Event.find(event_id)
    Accounts::Contacts::Events::Woofbot.new(event).call
  end
end
