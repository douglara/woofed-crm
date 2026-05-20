module Events
  class CreateActivityTool < ApplicationTool
    tool_name 'events_create_activity'
    description 'Schedule a task/activity (call, meeting, follow-up) on a deal or contact timeline. Provide deal_id or contact_id.'

    arguments do
      optional(:deal_id).filled(:integer).description('Deal ID this activity will be attached to')
      optional(:contact_id).filled(:integer).description('Contact ID this activity will be attached to')
      required(:title).filled(:string).description('Activity title')
      optional(:content).filled(:string).description('Activity description/notes')
      optional(:scheduled_at).filled(:string).description('When the activity is scheduled (ISO8601 UTC)')
      optional(:done).filled(:bool).description('Mark the activity as already done')
    end

    def call(title:, deal_id: nil, contact_id: nil, content: nil, scheduled_at: nil, done: false)
      handle_with_exception do
        return unprocessable_error('Provide deal_id or contact_id') if deal_id.blank? && contact_id.blank?

        contact_id ||= Deal.find(deal_id).contact_id
        params = { kind: 'activity', title: title, content: content,
                   scheduled_at: scheduled_at, done: done,
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
