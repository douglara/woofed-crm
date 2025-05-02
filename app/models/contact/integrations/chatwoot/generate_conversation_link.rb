class Contact::Integrations::Chatwoot::GenerateConversationLink
  def initialize(contact)
    @contact = contact
  end

  def call
    chatwoot = fetch_chatwoot_for_account
    chatwoot_contact_id = @contact.additional_attributes['chatwoot_id']

    unless chatwoot && chatwoot_contact_id
      return { error: 'There is no chatwoot integration or chatwoot_id on contact' }
    end

    conversation_id = fetch_conversation_id(chatwoot, chatwoot_contact_id)
    return { error: "There is no conversation on contact id:#{chatwoot_contact_id}" } unless conversation_id

    { ok: build_conversation_url(chatwoot, conversation_id) }
  end

  private

  def fetch_chatwoot_for_account
    Apps::Chatwoot.first
  end

  def fetch_conversation_id(chatwoot, chatwoot_contact_id)
    conversations = Accounts::Apps::Chatwoots::GetConversations.call(chatwoot, chatwoot_contact_id)
    conversations.dig(:ok, 0, 'id')
  end

  def build_conversation_url(chatwoot, conversation_id)
    conversation_path = "app/accounts/#{chatwoot.chatwoot_account_id}/conversations/#{conversation_id}"
    chatwoot.chatwoot_endpoint_url + conversation_path
  end
end
