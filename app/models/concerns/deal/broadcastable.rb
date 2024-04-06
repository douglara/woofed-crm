module Deal::Broadcastable
  extend ActiveSupport::Concern
  included do
    after_create_commit do
      if done == false
        broadcast_prepend_later_to [contact_id, 'events'],
                                   partial: 'accounts/contacts/events/event',
                                   target: "events_to_do_#{contact.id}"
      else
        broadcast_prepend_later_to [contact_id, 'events'],
                                   partial: 'accounts/contacts/events/event',
                                   target: "events_done_#{contact.id}"
      end
    end

    def broadcast_events
      events_to_do = deal.contact.events.to_do.limit(5).to_a
      broadcast_replace_later_to [contact_id, 'events'], target: "events_to_do_#{contact.id}",
                                                         partial: 'accounts/contacts/events/events_to_do', locals: { deal: deal, events: events_to_do }
      broadcast_replace_later_to [contact_id, 'events'], target: "events_done_#{contact.id}",
                                                         partial: 'accounts/contacts/events/events_done', locals: { deal: deal }
    end

    after_update_commit do
      if saved_change_to_done_at?
        broadcast_events
      else
        broadcast_replace_later_to [contact_id, 'events'],
                                   partial: 'accounts/contacts/events/event'
      end
    end

    after_destroy_commit do
      broadcast_remove_to [contact_id, 'events']
    end
  end
end
