class Accounts::Apps::Chatwoots::RemoveChatwootIdFromContacts
    def self.call(account)
        account.contacts.where.not(additional_attributes: nil).each do |contact|
            contact.additional_attributes.delete('chatwoot_id')
            contact.save
        end
        return {ok: 'Contact chatwoot id removed successfully!' }
    end
end
  