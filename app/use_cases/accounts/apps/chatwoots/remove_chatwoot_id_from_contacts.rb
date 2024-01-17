class Accounts::Apps::Chatwoots::RemoveChatwootIdFromContacts
  def self.call(account)
    account.contacts.where("additional_attributes -> 'chatwoot_id' IS NOT NULL").find_each do |contact|
      contact.additional_attributes.delete('chatwoot_id')
      contact.save
    end
    return { ok: 'Contacts chatwoot id was successfully removed.' }
  end
end
  