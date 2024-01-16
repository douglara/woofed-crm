module Deal::Broadcastable
  extend ActiveSupport::Concern
  included do

    after_create_commit {
      if self.done == false
        broadcast_prepend_later_to [contact_id, 'events'],
        partial: "accounts/contacts/events/event",
        target: "events_to_do_#{contact.id}"
      else
        broadcast_prepend_later_to [contact_id, 'events'],
        partial: "accounts/contacts/events/event",
        target: "events_done_#{contact.id}"
      end
    }

    def broadcast_events
      broadcast_replace_later_to [contact_id, 'events'], target: "events_to_do_#{contact.id}", partial: 'accounts/contacts/events/events_to_do', locals: {deal: deal}
      broadcast_replace_later_to [contact_id, 'events'], target: "events_done_#{contact.id}", partial: 'accounts/contacts/events/events_done', locals: {deal: deal}
    end

    after_update_commit {
      if saved_change_to_done_at?
        broadcast_events()
      else
        broadcast_replace_later_to [contact_id, 'events'],
        partial: "accounts/contacts/events/event"
      end
    }

    after_destroy_commit {
      broadcast_remove_to [contact_id, 'events']
    }
  end
end
