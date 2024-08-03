class Accounts::Apps::Chatwoots::Create
  def self.call(account, chatwoot_params)
    chatwoot = account.apps_chatwoots.build(chatwoot_params)
    if chatwoot.save
      Accounts::Apps::Chatwoots::SyncChatwootWorker.perform_async(account.id, chatwoot.id)
      { ok: chatwoot }
    else
      { error: chatwoot }
    end
  end
end
