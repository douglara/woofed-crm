# frozen_string_literal: true

# The catch-up that keeps Woofed current between full loads.
#
# Salesforce sends nothing on its own until webhooks (CDC/Pub/Sub) are wired up,
# so freshness is bought by asking: every tick, each enabled object is queried
# for what changed since the last finished run of that object.
#
# The cron entry is global rather than per connection, and this no-ops when there
# is no connected org -- an install that never set Salesforce up pays one query
# for `Apps::Salesforce.first` per tick and nothing else.
#
# A tick that lands while the previous run of an object is still going skips that
# object rather than queueing a second one, so a run slower than the interval
# falls behind instead of piling up.
class Apps::Salesforce::Delta::PollJob < ApplicationJob
  self.queue_adapter = :good_job

  def perform
    Apps::Salesforce::Backfill::Start.new(Apps::Salesforce.first, kind: 'delta').call
  end
end
