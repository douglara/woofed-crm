class Accounts::EventsController < InternalController
  def calendar
  end

  def calendar_events
    start_date = Time.zone.parse(params[:start])
    end_date = Time.zone.parse(params[:end])

    events = Event.planned.where(scheduled_at: start_date..end_date)

    render json: events.map { |event| {
      id: event.id,
      title: event.title,
      start: event.scheduled_at.iso8601,
      backgroundColor: events_kind_color(event.kind),
      borderColor: events_kind_color(event.kind),
      extendedProps: {
        account_id: Current.account.id,
        contact_id: event.contact_id,
        deal_id: event.deal_id
      },
      url: account_deal_path(Current.account, event.deal)
    }}
  end

  private

  def events_kind_color(kind)
    case kind
    when 'chatwoot_message'
      '#369EF2'
    when 'evolution_api_message'
      '#26D367'
    else
      '#6857D9'
    end
  end
end
