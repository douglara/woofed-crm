class Accounts::Apps::Chatwoots::SyncExportContacts
  def self.call(account)
    response = export_contacts(account)
    return response
  end
  def self.export_contacts(account)
    account.contacts.where("additional_attributes -> 'chatwoot_id' IS NULL").find_in_batches(batch_size: 30) do |group|
      group.each do |contact|
        Accounts::Apps::Chatwoots::ExportContact.call(account.apps_chatwoots.first, contact)
      end
      sleep(15)
    end
    return {ok: 'Contacts exported successfully'}
  end
end

  