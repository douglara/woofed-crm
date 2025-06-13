# frozen_string_literal: true

class Apps::Chatwoot::Connection::RefreshJob < ApplicationJob
  self.queue_adapter = :good_job

  def perform
    Apps::Chatwoot.active.find_each do |chatwoot_app|
      Apps::Chatwoot::Connection::Refresh.new(chatwoot_app).call
    end
  end
end
