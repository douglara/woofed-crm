class Accounts::Apps::Chatwoots::RemoveChatwootIdContacts
    def self.call(account)
        account.contacts.where.not(additional_attributes: nil).each do |contact|
            contact.additional_attributes.delete('chatwoot_id')
            contact.save
        end
    end
end
  