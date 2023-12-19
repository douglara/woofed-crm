module Deal::Broadcastable
  extend ActiveSupport::Concern
  included do

    after_create_commit {
      if self.done == false
        broadcast_prepend_to [contact_id, 'events'],
        partial: "accounts/contacts/events/event",
        target: "events_planned_#{contact.id}"
      else
        broadcast_prepend_to [contact_id, 'events'],
        partial: "accounts/contacts/events/event",
        target: "events_not_planned_or_done_#{contact.id}"
      end
    }

    def broadcast_events
      broadcast_replace_later_to [contact_id, 'events'], target: "events_planned_#{contact.id}", partial: 'accounts/contacts/events/events_planned', locals: {deal: deal}
      broadcast_replace_later_to [contact_id, 'events'], target: "events_not_planned_or_done_#{contact.id}", partial: 'accounts/contacts/events/events_not_planned_or_done', locals: {deal: deal}
    end

    after_update_commit {
      if saved_change_to_done_at?
        broadcast_events()
      else
        broadcast_replace_to [contact_id, 'events'],
        partial: "accounts/contacts/events/event"
      end
    }

    after_destroy_commit {
      broadcast_remove_to [contact_id, 'events']
    }
  end
end
