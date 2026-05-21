# frozen_string_literal: true

class DealsResource < ApplicationResource
  uri_template 'woofed:///deals/{id}'
  resource_name 'deal'
  description 'A deal record, including its contact, stage, pipeline, deal_assignees and deal_products.'
  mime_type 'application/json'

  def content
    deal = Deal.find(params[:id])
    JSON.generate(deal.as_json(include: %i[contact stage pipeline deal_assignees deal_products]))
  end
end
