# frozen_string_literal: true

class Accounts::Contacts::Events::Woofbot
  def initialize(event)
    @event = event
    @account = event.account
  end

  def call
    if @event.from_me == false && woofbot_active? && @event.content.to_s.include?('?')
      woofbot_response = Accounts::Contacts::Events::GenerateAiResponse.new(@event).call

      if woofbot_response.present?

        event_params = {
          kind: @event.kind,
          contact_id: @event.contact_id,
          app_type: @event.app_type,
          app_id: @event.app_id,
          from_me: true,
          send_now: true,
          content: woofbot_response
        }

        event_params.merge!({ deal_id: @event.deal_id }) if @event.deal_id.present?

        @response_event = EventBuilder.new(@account.users.first,
                                           event_params).build

        @response_event.save
        @response_event
      end
    end
  end

  def woofbot_active?
    @account.site_url.present? && @account.woofbot_auto_reply
  end
end
