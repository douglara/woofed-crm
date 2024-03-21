class Accounts::Contacts::Events::Create
  def self.call(user, event_params, params, contact)
    ActiveRecord::Base.transaction do
      if params['event']['files'].present?
        events = build_event_attachments(user, event_params, params, contact)
        { ok: events }
      else
        event = create_and_save_event(user, event_params, contact)
        { ok: event }
      end
    end
  rescue StandardError => e
    { error: e.message }
  end

  def self.build_event_attachments(user, event_params, params, contact)
    params['event']['files'].map.with_index do |file, index|
      event = if index.zero?
                EventBuilder.new(user, event_params.merge({ contact: contact })).build
              else
                EventBuilder.new(user, event_params.except(:content).merge({ contact: contact })).build
              end
      set_attachment(event, file)
      build_and_save_event(event)
    end
  end

  def self.set_attachment(event, file)
    attachment = event.build_attachment
    attachment.file = file
    attachment.file_type = attachment.file.content_type.split('/').first
  end

  def self.create_and_save_event(user, event_params, contact)
    event = EventBuilder.new(user,
                             event_params.merge({ contact: contact })).build
    build_and_save_event(event)
  end

  def self.build_and_save_event(event)
    if event.save
      event
    else
      raise StandardError, event.errors.full_messages.join(', ')
    end
  end
end
