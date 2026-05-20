module Events
  class CreateNoteTool < ApplicationTool
    tool_name 'events_create_note'
    description 'Add a free-text note to a deal or contact timeline. Provide either deal_id or contact_id (or both).'

    arguments do
      optional(:deal_id).filled(:integer).description('Deal ID this note will be attached to')
      optional(:contact_id).filled(:integer).description('Contact ID this note will be attached to')
      required(:content).filled(:string).description('Note body')
      optional(:title).filled(:string).description('Optional note title')
    end

    def call(content:, deal_id: nil, contact_id: nil, title: nil)
      handle_with_exception do
        return unprocessable_error('Provide deal_id or contact_id') if deal_id.blank? && contact_id.blank?

        contact_id ||= Deal.find(deal_id).contact_id
        params = { kind: 'note', content: content, title: title,
                   deal_id: deal_id, contact_id: contact_id, from_me: true }.compact

        event = EventBuilder.new(current_user, params).build
        if event.save
          event.to_json
        else
          unprocessable_error(event.errors.full_messages)
        end
      end
    end
  end
end
