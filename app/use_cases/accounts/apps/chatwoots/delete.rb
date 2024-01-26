class Accounts::Apps::Chatwoots::Delete
  def self.call(account, chatwoot)
    if chatwoot.destroy
      Accounts::Apps::Chatwoots::RemoveChatwootIdFromContactsWorker.perform_async(account.id)
      { ok: 'Chatwoot was successfully destroyed.' }
    else
      { error: chatwoot }
    end
  end
end
