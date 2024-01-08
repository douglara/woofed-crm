class Accounts::Apps::Chatwoots::Create
  def self.call(account, chatwoot_params)
		chatwoot = account.apps_chatwoots.build(chatwoot_params)
		if chatwoot.save
			Accounts::Apps::Chatwoots::SyncImportContactsWorker.perform_async(chatwoot.id)
      Accounts::Apps::Chatwoots::SyncExportContactsWorker.perform_async(account.id)
			return { ok: chatwoot }
		else
			return { error: chatwoot }
		end
  end
end
