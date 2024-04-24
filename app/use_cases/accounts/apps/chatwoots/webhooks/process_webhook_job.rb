# frozen_string_literal: true

class Accounts::Apps::Chatwoots::Webhooks::ProcessWebhookJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Concurrency

  self.queue_adapter = :good_job

  good_job_control_concurrency_with(
    # Maximum number of jobs with the concurrency key to be
    # concurrently performed (excludes enqueued jobs)
    perform_limit: 1,
    key: -> { "#{self.class.name}-#{arguments.last}" }
  )

  def perform(event, _token)
    event_hash = JSON.parse(event)
    Accounts::Apps::Chatwoots::Webhooks::ProcessWebhook.call(event_hash)
  end
end
