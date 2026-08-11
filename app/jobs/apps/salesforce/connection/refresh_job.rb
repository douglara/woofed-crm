# frozen_string_literal: true

class Apps::Salesforce::Connection::RefreshJob < ApplicationJob
  self.queue_adapter = :good_job

  def perform
    Apps::Salesforce::Connection::Refresh.new(Apps::Salesforce.first).call
  end
end
