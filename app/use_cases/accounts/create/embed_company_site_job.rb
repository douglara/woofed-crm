class Accounts::Create::EmbedCompanySiteJob  < ApplicationJob
  self.queue_adapter = :good_job

  def perform(account_id)
    account = Account.find(account_id)
    Accounts::Create::EmbededCompanySite.new(account).call
  end
end
