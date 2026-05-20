module Deals
  class CreateTool < ApplicationTool
    tool_name 'deals_create'
    description 'Create a new deal. Requires contact_id and stage_id; pipeline_id is inferred from the stage when omitted.'

    arguments do
      required(:contact_id).filled(:integer).description('Contact ID this deal belongs to')
      required(:stage_id).filled(:integer).description('Stage ID where the deal will be placed')
      optional(:pipeline_id).filled(:integer).description('Pipeline ID. Must match the pipeline of the stage')
      optional(:name).filled(:string).description('Deal name/title')
      optional(:status).filled(:string).description('Deal status: open (default), won or lost')
      optional(:lost_reason).filled(:string).description('Reason (when status = lost)')
      optional(:custom_attributes).hash.description('Free-form custom fields')
    end

    def call(**attributes)
      handle_with_exception do
        params = ActionController::Parameters.new(attributes.compact).permit!
        deal = DealBuilder.new(current_user, params).perform

        if Deal::CreateOrUpdate.new(deal, params).call
          deal.to_json
        else
          unprocessable_error(deal.errors.full_messages)
        end
      end
    end
  end
end
