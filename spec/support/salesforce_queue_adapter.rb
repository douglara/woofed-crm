# The backfill jobs hand work to each other, and the test environment runs
# GoodJob inline. Without a test adapter, asserting that a job scheduled the next
# one would instead run the whole chain -- and a poll that reschedules itself
# would recurse until it gave up.
RSpec.shared_context 'with salesforce backfill jobs enqueued' do
  around do |example|
    jobs = [
      Apps::Salesforce::Backfill::ObjectJob,
      Apps::Salesforce::Backfill::PollJob,
      Apps::Salesforce::Backfill::DownloadJob
    ]
    # One shared adapter instance: the matchers read the registry of
    # ActiveJob::Base, so every job has to enqueue into that same one.
    adapter = ActiveJob::QueueAdapters::TestAdapter.new
    previous_base = ActiveJob::Base.queue_adapter
    previous = jobs.map { |job| [job, job.queue_adapter] }

    ActiveJob::Base.queue_adapter = adapter
    jobs.each { |job| job.queue_adapter = adapter }

    example.run

    ActiveJob::Base.queue_adapter = previous_base
    previous.each { |job, job_adapter| job.queue_adapter = job_adapter }
  end
end
