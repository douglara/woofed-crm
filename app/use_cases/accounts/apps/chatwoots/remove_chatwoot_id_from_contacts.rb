class Accounts::Apps::Chatwoots::RemoveChatwootIdFromContacts
  def self.call(account)
    account.contacts.where("additional_attributes -> 'chatwoot_id' IS NOT NULL").find_in_batches(batch_size: 30) do |group|
      group.each do |contact|
        contact.additional_attributes.delete('chatwoot_id')
        contact.save
      end
      sleep(30)
    end
    return {ok: 'Contact chatwoot id was successfully removed.' }
  end
end
  