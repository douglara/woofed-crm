module Deals
  class MarkLostTool < ApplicationTool
    tool_name 'deals_mark_lost'
    description 'Mark a deal as lost. Optionally provide the lost reason and timestamp.'

    arguments do
      required(:id).filled(:integer).description('Deal ID')
      optional(:lost_reason).filled(:string).description('Why the deal was lost')
      optional(:lost_at).filled(:string).description('ISO8601 UTC datetime the deal was lost. Defaults to now.')
    end

    def call(id:, lost_reason: nil, lost_at: nil)
      handle_with_exception do
        deal = Deal.find(id)
        attributes = { status: 'lost', lost_reason: lost_reason, lost_at: lost_at }.compact
        if Deal::CreateOrUpdate.new(deal, attributes).call
          deal.to_json
        else
          unprocessable_error(deal.errors.full_messages)
        end
      end
    end
  end
end
