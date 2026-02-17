require 'rails_helper'

RSpec.describe Deal do
  let!(:account) { create(:account) }
  let(:last_event) { Event.last }

  describe 'position' do
    let!(:pipeline) { create(:pipeline) }
    let!(:stage1) { create(:stage, pipeline:) }
    let!(:stage2) { create(:stage, pipeline:) }

    let!(:stage1_position1) { create(:deal, stage: stage1, position: 1) }
    let!(:stage1_position2) { create(:deal, stage: stage1, position: 2) }
    let!(:stage1_position3) { create(:deal, stage: stage1, position: 3) }

    let!(:stage2_position1) { create(:deal, stage: stage2, position: 1) }
    let!(:stage2_position2) { create(:deal, stage: stage2, position: 2) }
    let!(:stage2_position3) { create(:deal, stage: stage2, position: 3) }

    context 'moving between stages' do
      it 'move stage1_position1 to stage2 position 1 and create deal_stage_change event' do
        expect do
          Deal::CreateOrUpdate.new(stage1_position1, { stage: stage2, position: 1 }).call
        end.to change(Event, :count).by(1)

        expect(stage1_position2.reload.position).to eq 1
        expect(stage1_position3.reload.position).to eq 2

        expect(stage1_position1.reload.stage_id).to eq stage2.id

        expect(stage1_position1.position).to eq 1
        expect(stage2_position1.reload.position).to eq 2
        expect(stage2_position2.reload.position).to eq 3
        expect(stage2_position3.reload.position).to eq 4
        expect(last_event.kind).to eq('deal_stage_change')
      end

      it 'move stage1_position1 to stage2 position 2 and create deal_stage_change event' do
        expect do
          Deal::CreateOrUpdate.new(stage1_position1, { stage: stage2, position: 2 }).call
        end.to change(Event, :count).by(1)

        expect(stage1_position2.reload.position).to eq 1
        expect(stage1_position3.reload.position).to eq 2

        expect(stage1_position1.reload.stage_id).to eq stage2.id

        expect(stage2_position1.reload.position).to eq 1
        expect(stage1_position1.position).to eq 2
        expect(stage2_position2.reload.position).to eq 3
        expect(stage2_position3.reload.position).to eq 4
        expect(last_event.kind).to eq('deal_stage_change')
      end

      it 'move stage1_position1 to stage2 position 3 and create deal_stage_change event' do
        expect do
          Deal::CreateOrUpdate.new(stage1_position1, { stage: stage2, position: 3 }).call
        end.to change(Event, :count).by(1)

        expect(stage1_position2.reload.position).to eq 1
        expect(stage1_position3.reload.position).to eq 2

        expect(stage1_position1.reload.stage_id).to eq stage2.id

        expect(stage2_position1.reload.position).to eq 1
        expect(stage2_position2.reload.position).to eq 2
        expect(stage1_position1.position).to eq 3
        expect(stage2_position3.reload.position).to eq 4
        expect(last_event.kind).to eq('deal_stage_change')
      end

      it 'move stage1_position1 to stage2 position 250 and create deal_stage_change event' do
        expect do
          Deal::CreateOrUpdate.new(stage1_position1, { stage: stage2, position: 250 }).call
        end.to change(Event, :count).by(1)

        expect(stage1_position2.reload.position).to eq 1
        expect(stage1_position3.reload.position).to eq 2

        expect(stage1_position1.reload.stage_id).to eq stage2.id

        expect(stage2_position1.reload.position).to eq 1
        expect(stage2_position2.reload.position).to eq 2
        expect(stage2_position3.reload.position).to eq 3
        expect(stage1_position1.position).to eq 250
        expect(last_event.kind).to eq('deal_stage_change')
      end
    end

    context 'moving within the same stage' do
      it 'move stage1_position1 to position 2' do
        Deal::CreateOrUpdate.new(stage1_position1, { position: 2 }).call

        expect(stage1_position1.reload.position).to eq 2
        expect(stage1_position2.reload.position).to eq 1
        expect(stage1_position3.reload.position).to eq 3
      end

      it 'move stage1_position1 to position 3' do
        Deal::CreateOrUpdate.new(stage1_position1, { position: 3 }).call

        expect(stage1_position1.reload.position).to eq 3
        expect(stage1_position2.reload.position).to eq 1
        expect(stage1_position3.reload.position).to eq 2
      end
    end

    context 'create a deal' do
      context 'when position is not provided' do
        it 'places the new deal at the end of the stage' do
          new_deal = build(:deal, stage: stage1)
          new_deal = Deal::CreateOrUpdate.new(new_deal, {}).call

          expect(stage1_position1.reload.position).to eq 1
          expect(stage1_position2.reload.position).to eq 2
          expect(stage1_position3.reload.position).to eq 3
          expect(new_deal.reload.position).to eq 4
        end
      end

      context 'when position is provided' do
        it 'inserts the new deal at the specified position' do
          new_deal = build(:deal, stage: stage1, position: 2)
          new_deal = Deal::CreateOrUpdate.new(new_deal, {}).call

          expect(stage1_position1.reload.position).to eq 1
          expect(new_deal.reload.position).to eq 2
          expect(stage1_position2.reload.position).to eq 3
          expect(stage1_position3.reload.position).to eq 4
        end
      end
    end
  end
end
