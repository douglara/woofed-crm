class AddPipelineInDeal < ActiveRecord::Migration[6.1]
  def change
    add_reference :deals, :pipeline, null: true, index: true
    Deal.where(pipeline_id: nil).each do | d |
      d.update_column(:pipeline_id, d.stage.pipeline_id)
    end
  end
end
