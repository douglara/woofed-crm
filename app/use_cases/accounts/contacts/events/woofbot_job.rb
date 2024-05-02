# frozen_string_literal: true

class Accounts::Contacts::Events::WoofbotJob < ApplicationJob
  self.queue_adapter = :good_job

  def perform(event_id)
    event = Event.find(event_id)
    Accounts::Contacts::Events::Woofbot.new(event).call
  end
end
