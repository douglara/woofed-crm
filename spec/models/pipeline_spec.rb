require 'rails_helper'

RSpec.describe Pipeline do
  let!(:account) { create(:account) }

  describe 'destroy' do
    let!(:pipeline) { create(:pipeline) }
    let!(:another_pipeline) { create(:pipeline) }
    let!(:stage) { create(:stage, pipeline:) }
    let!(:stage_from_another_pipeline) { create(:stage, pipeline: another_pipeline) }
    let!(:another_stage) { create(:stage, pipeline:) }
    let!(:deal) { create(:deal, stage:) }
    let!(:another_deal) { create(:deal, stage: another_stage) }
    let!(:deal_from_another_pipeline) { create(:deal, stage: stage_from_another_pipeline, pipeline: another_pipeline) }

    it 'destroys the pipeline, associated stages and associated deals' do
      expect do
         pipeline.destroy
      end.to change(Pipeline, :count).by(-1)
      .and change(Stage, :count).by(-2)
      .and change(Deal, :count).by(-2)

      expect(stage_from_another_pipeline).to be_persisted
      expect(deal_from_another_pipeline).to be_persisted
    end
  end
end
