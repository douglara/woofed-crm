module Deals
  class UpdateTool < ApplicationTool
    tool_name 'deals_update'
    description 'Update an existing deal by ID. Only fields provided will be changed.'

    arguments do
      required(:id).filled(:integer).description('Deal ID')
      optional(:name).filled(:string).description('Deal name/title')
      optional(:status).filled(:string).description('Deal status: open, won or lost')
      optional(:stage_id).filled(:integer).description('Move deal to a different stage')
      optional(:pipeline_id).filled(:integer).description('Move deal to a different pipeline (must match stage)')
      optional(:lost_reason).filled(:string).description('Reason when status is lost')
      optional(:lost_at).filled(:string).description('When the deal was marked lost (ISO8601 UTC)')
      optional(:won_at).filled(:string).description('When the deal was marked won (ISO8601 UTC)')
      optional(:custom_attributes).hash.description('Free-form custom fields')
    end

    def call(id:, **attributes)
      handle_with_exception do
        deal = Deal.find(id)
        if Deal::CreateOrUpdate.new(deal, attributes.compact).call
          deal.to_json
        else
          unprocessable_error(deal.errors.full_messages)
        end
      end
    end
  end
end
