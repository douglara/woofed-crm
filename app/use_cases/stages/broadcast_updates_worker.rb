class Stages::BroadcastUpdatesWorker
  include Sidekiq::Worker

  def perform(stage_id, filter_status_deal = 'all')
    stage = Stage.find(stage_id)
    Stages::BroadcastUpdates.call(stage, filter_status_deal)
  end
end
