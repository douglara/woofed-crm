class Accounts::Apps::Chatwoots::SyncExportContacts
    def self.call(account)
        response = export_contacts(account)
        return response
    end
    def self.export_contacts(account)
        account.contacts.where("additional_attributes -> 'chatwoot_id' IS NULL").each do |contact|
            Accounts::Apps::Chatwoots::ExportContact.call(account.apps_chatwoots.first, contact)
        end
        return {ok: 'Contacts exported successfully'}
    end
end

  