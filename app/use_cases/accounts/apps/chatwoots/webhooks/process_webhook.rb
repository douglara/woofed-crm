class Accounts::Apps::Chatwoots::Webhooks::ProcessWebhook
  def self.call(webhook)
    chatwoot = Apps::Chatwoot.find_by(embedding_token: webhook['token'])
    puts('Processa o webhook')
    puts(webhook)

    if webhook['event'].include?('contact_')
      Accounts::Apps::Chatwoots::Webhooks::Events::Contact.call(
        chatwoot, webhook
      )
    elsif webhook['event'] == 'conversation_updated'
      Accounts::Apps::Chatwoots::Webhooks::Events::ConversationUpdated.call(
        chatwoot, webhook
      )
    elsif webhook['event'].include?('message_')
      Accounts::Apps::Chatwoots::Webhooks::Events::Message.call(
        chatwoot, webhook
      )
    end

    { ok: chatwoot }
  end
end
