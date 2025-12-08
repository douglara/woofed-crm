module DealConcern
  def permitted_deal_params
    [
      :name,
      :status,
      :stage_id,
      :pipeline_id,
      :contact_id,
      :position,
      :lost_reason,
      { contact_attributes: %i[id full_name phone email] },
      { custom_attributes: {} }
    ]
  end
end
