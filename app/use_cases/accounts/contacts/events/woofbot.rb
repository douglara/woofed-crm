# frozen_string_literal: true

class Accounts::Contacts::Events::Woofbot
  def initialize(event)
    @event = event
    @account = event.account
    @ai_assistent = Apps::AiAssistent.first
  end

  def call
    return unless woofbot_should_be_run?

    @woofbot_response = Accounts::Contacts::Events::GenerateAiResponse.new(@event).call
    create_reply_event if @woofbot_response.present?
  end

  def create_reply_event
    event_params = {
      kind: @event.kind,
      contact_id: @event.contact_id,
      app_type: @event.app_type,
      app_id: @event.app_id,
      from_me: true,
      send_now: true,
      content: "#{@woofbot_response}\n\n🤖 Mensagem automática"
    }

    event_params.merge!({ deal_id: @event.deal_id }) if @event.deal_id.present?

    @response_event = EventBuilder.new(@account.users.first,
                                        event_params).build

    @response_event.save
    @response_event
  end

  def woofbot_should_be_run?
    @event.from_me == false && woofbot_active? && event_is_question?
  end

  def event_is_question?
    @event.content.to_s.include?('?')
  end

  def woofbot_active?
    @account.site_url.present? && @ai_assistent.auto_reply
  end
end
