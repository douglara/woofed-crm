module Deals
  class MarkWonTool < ApplicationTool
    tool_name 'deals_mark_won'
    description 'Mark a deal as won. Optionally provide the timestamp the deal was won.'

    arguments do
      required(:id).filled(:integer).description('Deal ID')
      optional(:won_at).filled(:string).description('ISO8601 UTC datetime the deal was won. Defaults to now.')
    end

    def call(id:, won_at: nil)
      handle_with_exception do
        deal = Deal.find(id)
        attributes = { status: 'won', won_at: won_at }.compact
        if Deal::CreateOrUpdate.new(deal, attributes).call
          deal.to_json
        else
          unprocessable_error(deal.errors.full_messages)
        end
      end
    end
  end
end
