class Accounts::Apps::WppConnects::Connections::RefreshStatusJob < ApplicationJob
  self.queue_adapter = :good_job

  def perform()
    Accounts::Apps::WppConnects::Connections::RefreshStatus.call()
  end
end