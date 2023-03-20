class Accounts::Apps::WppConnects::Sync::FullSyncWorker
  include Sidekiq::Worker

  def perform(wpp_connect_id)
    Accounts::Apps::WppConnects::Sync::FullSync.call(wpp_connect_id)
  end
end